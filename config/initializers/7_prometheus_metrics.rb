require 'prometheus/client'

# Keep separate directories for separate processes
def prometheus_default_multiproc_dir
  return unless Rails.env.development? || Rails.env.test?

  if Gitlab::Runtime.sidekiq?
    Rails.root.join('tmp/prometheus_multiproc_dir/sidekiq')
  elsif Gitlab::Runtime.unicorn?
    Rails.root.join('tmp/prometheus_multiproc_dir/unicorn')
  elsif Gitlab::Runtime.puma?
    Rails.root.join('tmp/prometheus_multiproc_dir/puma')
  else
    Rails.root.join('tmp/prometheus_multiproc_dir')
  end
end

Prometheus::Client.configure do |config|
  config.logger = Rails.logger # rubocop:disable Gitlab/RailsLogger

  config.initial_mmap_file_size = 4 * 1024

  config.multiprocess_files_dir = ENV['prometheus_multiproc_dir'] || prometheus_default_multiproc_dir

  config.pid_provider = Prometheus::PidProvider.method(:worker_id)
end

Gitlab::Application.configure do |config|
  # 0 should be Sentry to catch errors in this middleware
  config.middleware.insert(1, Gitlab::Metrics::RequestsRackMiddleware)
end

Sidekiq.configure_server do |config|
  config.on(:startup) do
    # webserver metrics are cleaned up in config.ru: `warmup` block
    Prometheus::CleanupMultiprocDirService.new.execute
    # In production, sidekiq is run in a multi-process setup where processes might interfere
    # with each other cleaning up and reinitializing prometheus database files, which is why
    # we're re-doing the work every time here.
    # A cleaner solution would be to run the cleanup pre-fork, and the initialization once
    # after all workers have forked, but I don't know how at this point.
    ::Prometheus::Client.reinitialize_on_pid_change(force: true)

    Gitlab::Metrics::Exporter::SidekiqExporter.instance.start
  end
end

if !Rails.env.test? && Gitlab::Metrics.prometheus_metrics_enabled?
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    defined?(::Prometheus::Client.reinitialize_on_pid_change) && Prometheus::Client.reinitialize_on_pid_change

    Gitlab::Metrics::Samplers::RubySampler.initialize_instance(Settings.monitoring.ruby_sampler_interval).start
  end

  Gitlab::Cluster::LifecycleEvents.on_master_start do
    ::Prometheus::Client.reinitialize_on_pid_change(force: true)

    if Gitlab::Runtime.unicorn?
      Gitlab::Metrics::Samplers::UnicornSampler.instance(Settings.monitoring.unicorn_sampler_interval).start
    elsif Gitlab::Runtime.puma?
      Gitlab::Metrics::Samplers::PumaSampler.instance(Settings.monitoring.puma_sampler_interval).start
    end

    Gitlab::Metrics::RequestsRackMiddleware.initialize_http_request_duration_seconds
  end
end

if Gitlab::Runtime.app_server?
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
