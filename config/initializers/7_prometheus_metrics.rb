# frozen_string_literal: true

require Rails.root.join('metrics_server', 'metrics_server')

# Keep separate directories for separate processes
def metrics_temp_dir
  return unless Rails.env.development? || Rails.env.test?

  if Gitlab::Runtime.sidekiq?
    Rails.root.join('tmp/prometheus_multiproc_dir/sidekiq')
  elsif Gitlab::Runtime.puma?
    Rails.root.join('tmp/prometheus_multiproc_dir/puma')
  else
    Rails.root.join('tmp/prometheus_multiproc_dir')
  end
end

def prometheus_metrics_dir
  ENV['prometheus_multiproc_dir'] || metrics_temp_dir
end

def puma_master?
  Prometheus::PidProvider.worker_id == 'puma_master'
end

# Whether a dedicated process should run that serves Rails application metrics, as opposed
# to using a Rails controller.
def puma_dedicated_metrics_server?
  Settings.monitoring.web_exporter.enabled
end

if puma_master?
  # The following is necessary to ensure stale Prometheus metrics don't accumulate over time.
  # It needs to be done as early as possible to ensure new metrics aren't being deleted.
  #
  # Note that this should not happen for Sidekiq. Since Sidekiq workers are spawned from the
  # sidekiq-cluster script, we perform this cleanup in `sidekiq_cluster/cli.rb` instead,
  # since it must happen prior to any worker processes or the metrics server starting up.
  Prometheus::CleanupMultiprocDirService.new(prometheus_metrics_dir).execute

  ::Prometheus::Client.reinitialize_on_pid_change(force: true)
end

::Prometheus::Client.configure do |config|
  config.logger = Gitlab::AppLogger

  config.multiprocess_files_dir = prometheus_metrics_dir

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

    MetricsServer.start_for_puma if puma_dedicated_metrics_server?
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
    # Since we are observing a metrics server from the Puma primary, we would inherit
    # this supervision thread after forking into workers, so we need to explicitly stop it here.
    ::MetricsServer::PumaProcessSupervisor.instance.stop if puma_dedicated_metrics_server?

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

if Gitlab::Runtime.puma? && puma_dedicated_metrics_server?
  Gitlab::Cluster::LifecycleEvents.on_before_graceful_shutdown do
    # We need to ensure that before we re-exec or shutdown server
    # we also stop the metrics server
    ::MetricsServer::PumaProcessSupervisor.instance.shutdown
  end

  Gitlab::Cluster::LifecycleEvents.on_before_master_restart do
    # We need to ensure that before we re-exec server
    # we also stop the metrics server
    #
    # We do it again, for being extra safe,
    # but it should not be needed
    ::MetricsServer::PumaProcessSupervisor.instance.shutdown
  end
end
