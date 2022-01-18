# frozen_string_literal: true

require_relative '../config/boot'

require_relative 'dependencies'

class MetricsServer # rubocop:disable Gitlab/NamespacedClass
  class << self
    def spawn(target, metrics_dir:, wipe_metrics_dir: false, trapped_signals: [])
      raise "The only valid target is 'sidekiq' currently" unless target == 'sidekiq'

      pid = Process.fork

      if pid.nil? # nil means we're inside the fork
        # Remove any custom signal handlers the parent process had registered, since we do
        # not want to inherit them, and Ruby forks with a `clone` that has the `CLONE_SIGHAND`
        # flag set.
        Gitlab::ProcessManagement.modify_signals(trapped_signals, 'DEFAULT')

        server = MetricsServer.new(target, metrics_dir, wipe_metrics_dir)
        # This rewrites /proc/cmdline, since otherwise tools like `top` will show the
        # parent process `cmdline` which is really confusing.
        $0 = server.name

        server.start
      else
        Process.detach(pid)
      end

      pid
    end
  end

  def initialize(target, metrics_dir, wipe_metrics_dir)
    @target = target
    @metrics_dir = metrics_dir
    @wipe_metrics_dir = wipe_metrics_dir
  end

  def start
    ::Prometheus::Client.configure do |config|
      config.multiprocess_files_dir = @metrics_dir
      config.pid_provider = proc { "#{@target}_exporter" }
    end

    FileUtils.mkdir_p(@metrics_dir, mode: 0700)
    ::Prometheus::CleanupMultiprocDirService.new.execute if @wipe_metrics_dir

    # We need to `warmup: true` since otherwise the sampler and exporter threads enter
    # a race where not all Prometheus db files will be visible to the exporter, resulting
    # in missing metrics.
    # Warming up ensures that these files exist prior to the exporter starting up.
    Gitlab::Metrics::Samplers::RubySampler.initialize_instance(warmup: true).start

    exporter_class = "Gitlab::Metrics::Exporter::#{@target.camelize}Exporter".constantize
    settings = Settings.new(Settings.monitoring[name])
    server = exporter_class.instance(settings, gc_requests: true, synchronous: true)

    server.start
  end

  def name
    "#{@target}_exporter"
  end
end
