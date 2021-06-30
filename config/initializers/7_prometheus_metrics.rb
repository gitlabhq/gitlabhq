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

Sidekiq.configure_server do |config|
  config.on(:startup) do
    # Do not clean the metrics directory here - the supervisor script should
    # have already taken care of that
    Gitlab::Metrics::Exporter::SidekiqExporter.instance.start
  end
end

if !Rails.env.test? && Gitlab::Metrics.prometheus_metrics_enabled?
  # When running Puma in a Single mode, `on_master_start` and `on_worker_start` are the same.
  # Thus, we order these events to run `reinitialize_on_pid_change` with `force: true` first.
  Gitlab::Cluster::LifecycleEvents.on_master_start do
    # Ensure that stale Prometheus metrics don't accumulate over time
    ::Prometheus::CleanupMultiprocDirService.new.execute

    ::Prometheus::Client.reinitialize_on_pid_change(force: true)

    if Gitlab::Runtime.puma?
      Gitlab::Metrics::Samplers::PumaSampler.instance.start
    end

    Gitlab::Metrics.gauge(:deployments, 'GitLab Version', {}, :max).set({ version: Gitlab::VERSION }, 1)

    unless Gitlab::Runtime.sidekiq?
      Gitlab::Metrics::RequestsRackMiddleware.initialize_metrics
    end

    Gitlab::Ci::Parsers.instrument!
  rescue IOError => e
    Gitlab::ErrorTracking.track_exception(e)
    Gitlab::Metrics.error_detected!
  end

  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    defined?(::Prometheus::Client.reinitialize_on_pid_change) && ::Prometheus::Client.reinitialize_on_pid_change

    Gitlab::Metrics::Samplers::RubySampler.initialize_instance.start
    Gitlab::Metrics::Samplers::DatabaseSampler.initialize_instance.start
    Gitlab::Metrics::Samplers::ThreadsSampler.initialize_instance.start

    if Gitlab::Runtime.action_cable?
      Gitlab::Metrics::Samplers::ActionCableSampler.instance.start
    end

    if Gitlab.ee? && Gitlab::Runtime.sidekiq?
      Gitlab::Metrics::Samplers::GlobalSearchSampler.instance.start
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

  # DEPRECATED: TO BE REMOVED
  # This is needed to implement blackout period of `web_exporter`
  # https://gitlab.com/gitlab-org/gitlab/issues/35343#note_238479057
  Gitlab::Cluster::LifecycleEvents.on_before_blackout_period do
    Gitlab::Metrics::Exporter::WebExporter.instance.mark_as_not_running!
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
