# frozen_string_literal: true

# Keep separate directories for separate processes
def prometheus_default_multiproc_dir
  return unless Rails.env.development? || Rails.env.test?

  if Gitlab::Runtime.sidekiq?
    Rails.root.join('tmp/prometheus_multiproc_dir/sidekiq')
  elsif Gitlab::Runtime.puma?
    Rails.root.join('tmp/prometheus_multiproc_dir/puma')
  else
    Rails.root.join('tmp/prometheus_multiproc_dir')
  end
end

::Prometheus::Client.configure do |config|
  config.logger = Gitlab::AppLogger

  config.initial_mmap_file_size = 4 * 1024

  config.multiprocess_files_dir = ENV['prometheus_multiproc_dir'] || prometheus_default_multiproc_dir

  config.pid_provider = ::Prometheus::PidProvider.method(:worker_id)
end

Gitlab::Application.configure do |config|
  # 0 should be Sentry to catch errors in this middleware
  config.middleware.insert_after(Labkit::Middleware::Rack, Gitlab::Metrics::RequestsRackMiddleware)
end

if Gitlab::Runtime.sidekiq? && (!ENV['SIDEKIQ_WORKER_ID'] || ENV['SIDEKIQ_WORKER_ID'] == '0')
  # The single worker outside of a sidekiq-cluster, or the first worker (sidekiq_0)
  # in a cluster of processes, is responsible for serving health checks.
  #
  # Do not clean the metrics directory here - the supervisor script should
  # have already taken care of that.
  Sidekiq.configure_server do |config|
    config.on(:startup) do
      # In https://gitlab.com/gitlab-org/gitlab/-/issues/345804 we are looking to
      # only serve health-checks from a worker process; for backwards compatibility
      # we still go through the metrics exporter server, but start to configure it
      # with the new settings keys.
      exporter_settings = Settings.monitoring.sidekiq_health_checks
      Gitlab::Metrics::Exporter::SidekiqExporter.instance(exporter_settings).start
    end
  end
end

if !Rails.env.test? && Gitlab::Metrics.prometheus_metrics_enabled?
  # When running Puma in a Single mode, `on_master_start` and `on_worker_start` are the same.
  # Thus, we order these events to run `reinitialize_on_pid_change` with `force: true` first.
  Gitlab::Cluster::LifecycleEvents.on_master_start do
    ::Prometheus::Client.reinitialize_on_pid_change(force: true)

    if Gitlab::Runtime.puma?
      Gitlab::Metrics::Samplers::PumaSampler.instance.start
    end

    Gitlab::Metrics.gauge(:deployments, 'GitLab Version', {}, :max).set({ version: Gitlab::VERSION, revision: Gitlab.revision }, 1)

    if Gitlab::Runtime.web_server?
      Gitlab::Metrics::RequestsRackMiddleware.initialize_metrics
    end

    Gitlab::Ci::Parsers.instrument!
  rescue IOError => e
    Gitlab::ErrorTracking.track_exception(e)
    Gitlab::Metrics.error_detected!
  end

  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    defined?(::Prometheus::Client.reinitialize_on_pid_change) && ::Prometheus::Client.reinitialize_on_pid_change
    logger = Gitlab::AppLogger
    Gitlab::Metrics::Samplers::RubySampler.initialize_instance(logger: logger).start
    Gitlab::Metrics::Samplers::DatabaseSampler.initialize_instance(logger: logger).start
    Gitlab::Metrics::Samplers::ThreadsSampler.initialize_instance(logger: logger).start

    if Gitlab::Runtime.web_server?
      Gitlab::Metrics::Samplers::ActionCableSampler.instance(logger: logger).start
    end

    if Gitlab.ee? && Gitlab::Runtime.sidekiq?
      Gitlab::Metrics::Samplers::GlobalSearchSampler.instance(logger: logger).start
    end

    Gitlab::Ci::Parsers.instrument!
  rescue IOError => e
    Gitlab::ErrorTracking.track_exception(e)
    Gitlab::Metrics.error_detected!
  end
end

if Gitlab::Runtime.web_server?
  Gitlab::Cluster::LifecycleEvents.on_master_start do
    Gitlab::Metrics::Exporter::WebExporter.instance.start
  end

  Gitlab::Cluster::LifecycleEvents.on_before_graceful_shutdown do
    # We need to ensure that before we re-exec or shutdown server
    # we do stop the exporter
    Gitlab::Metrics::Exporter::WebExporter.instance.stop
  end

  Gitlab::Cluster::LifecycleEvents.on_before_master_restart do
    # We need to ensure that before we re-exec server
    # we do stop the exporter
    #
    # We do it again, for being extra safe,
    # but it should not be needed
    Gitlab::Metrics::Exporter::WebExporter.instance.stop
  end

  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    # The `#close_on_exec=` takes effect only on `execve`
    # but this does not happen for Ruby fork
    #
    # This does stop server, as it is running on master.
    Gitlab::Metrics::Exporter::WebExporter.instance.stop
  end
end
