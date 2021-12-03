# frozen_string_literal: true

require_relative '../config/bundler_setup'

require_relative 'dependencies'

class MetricsServer # rubocop:disable Gitlab/NamespacedClass
  class << self
    def spawn(target, gitlab_config: nil)
      cmd = "#{Rails.root}/bin/metrics-server"
      env = {
        'METRICS_SERVER_TARGET' => target,
        'GITLAB_CONFIG' => gitlab_config
      }

      Process.spawn(env, cmd, err: $stderr, out: $stdout).tap do |pid|
        Process.detach(pid)
      end
    end
  end

  def initialize(target, metrics_dir)
    @target = target
    @metrics_dir = metrics_dir
  end

  def start
    ::Prometheus::Client.configure do |config|
      config.multiprocess_files_dir = @metrics_dir
    end

    FileUtils.mkdir_p(@metrics_dir, mode: 0700)
    ::Prometheus::CleanupMultiprocDirService.new.execute

    settings = Settings.monitoring.sidekiq_exporter
    exporter_class = "Gitlab::Metrics::Exporter::#{@target.camelize}Exporter".constantize
    server = exporter_class.instance(settings, synchronous: true)

    server.start
  end
end
