require 'prometheus/client'
require 'prometheus/client/support/unicorn'

Prometheus::Client.configure do |config|
  config.logger = Rails.logger

  config.initial_mmap_file_size = 4 * 1024
  config.multiprocess_files_dir = ENV['prometheus_multiproc_dir']

  if Rails.env.development? || Rails.env.test?
    config.multiprocess_files_dir ||= Rails.root.join('tmp/prometheus_multiproc_dir')
  end

  config.pid_provider = Prometheus::Client::Support::Unicorn.method(:worker_pid_provider)
end

Gitlab::Application.configure do |config|
  # 0 should be Sentry to catch errors in this middleware
  config.middleware.insert(1, Gitlab::Metrics::RequestsRackMiddleware)
end

if !Rails.env.test? && Gitlab::Metrics.prometheus_metrics_enabled?
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    defined?(::Prometheus::Client.reinitialize_on_pid_change) && Prometheus::Client.reinitialize_on_pid_change

    if defined?(::Unicorn)
      Gitlab::Metrics::Samplers::UnicornSampler.initialize_instance(Settings.monitoring.unicorn_sampler_interval).start
    end

    Gitlab::Metrics::Samplers::RubySampler.initialize_instance(Settings.monitoring.ruby_sampler_interval).start
  end

  if defined?(::Puma)
    Gitlab::Cluster::LifecycleEvents.on_master_start do
      Gitlab::Metrics::Samplers::PumaSampler.initialize_instance(Settings.monitoring.puma_sampler_interval).start
    end
  end
end

Gitlab::Cluster::LifecycleEvents.on_master_restart do
  # The following is necessary to ensure stale Prometheus metrics don't
  # accumulate over time. It needs to be done in this hook as opposed to
  # inside an init script to ensure metrics files aren't deleted after new
  # unicorn workers start after a SIGUSR2 is received.
  prometheus_multiproc_dir = ENV['prometheus_multiproc_dir']
  if prometheus_multiproc_dir
    old_metrics = Dir[File.join(prometheus_multiproc_dir, '*.db')]
    FileUtils.rm_rf(old_metrics)
  end
end
