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

def puma_metrics_server_process?
  Prometheus::PidProvider.worker_id == 'puma_master'
end

def sidekiq_metrics_server_process?
  Gitlab::Runtime.sidekiq? && (!ENV['SIDEKIQ_WORKER_ID'] || ENV['SIDEKIQ_WORKER_ID'] == '0')
end

if puma_metrics_server_process? || sidekiq_metrics_server_process?
  # The following is necessary to ensure stale Prometheus metrics don't accumulate over time.
  # It needs to be done as early as here to ensure metrics files aren't deleted.
  # After we hit our app in `warmup`, first metrics and corresponding files already being created,
  # for example in `lib/gitlab/metrics/requests_rack_middleware.rb`.
  Prometheus::CleanupMultiprocDirService.new.execute

  ::Prometheus::Client.reinitialize_on_pid_change(force: true)
end

::Prometheus::Client.configure do |config|
  config.logger = Gitlab::AppLogger

  config.multiprocess_files_dir = ENV['prometheus_multiproc_dir'] || prometheus_default_multiproc_dir

  config.pid_provider = ::Prometheus::PidProvider.method(:worker_id)
end

Gitlab::Application.configure do |config|
  # 0 should be Sentry to catch errors in this middleware
  config.middleware.insert_after(Labkit::Middleware::Rack, Gitlab::Metrics::RequestsRackMiddleware)
end

# Any actions beyond this check should only execute outside of tests, when running in an application
# context (i.e. not in the Rails console or rspec) and when users have enabled metrics.
return if Rails.env.test? || !Gitlab::Runtime.application? || !Gitlab::Metrics.prometheus_metrics_enabled?

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

Gitlab::Cluster::LifecycleEvents.on_master_start do
  Gitlab::Metrics.gauge(:deployments, 'GitLab Version', {}, :max).set({ version: Gitlab::VERSION, revision: Gitlab.revision }, 1)

  if Gitlab::Runtime.puma?
    Gitlab::Metrics::Samplers::PumaSampler.instance.start

    # Starts a metrics server to export metrics from the Puma primary.
    Gitlab::Metrics::Exporter::WebExporter.instance.start
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

  if Gitlab::Runtime.puma?
    # Since we are running a metrics server on the Puma primary, we would inherit
    # this thread after forking into workers, so we need to explicitly stop it here.
    # NOTE: This will not be necessary anymore after moving to an external server
    # process via https://gitlab.com/gitlab-org/gitlab/-/issues/350548
    Gitlab::Metrics::Exporter::WebExporter.instance.stop

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

if Gitlab::Runtime.puma?
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
end
