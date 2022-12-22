# frozen_string_literal: true

require_relative '../config/boot'

class MetricsServer # rubocop:disable Gitlab/NamespacedClass
  # The singleton instance used to supervise the Puma metrics server.
  PumaProcessSupervisor = Class.new(Gitlab::ProcessSupervisor)

  class << self
    def version
      Rails.root.join('GITLAB_METRICS_EXPORTER_VERSION').read.chomp
    end

    def start_for_puma
      metrics_dir = ::Prometheus::Client.configuration.multiprocess_files_dir

      start_server = proc do
        MetricsServer.spawn('puma', metrics_dir: metrics_dir).tap do |pid|
          Gitlab::AppLogger.info("Starting Puma metrics server with pid #{pid}")
        end
      end

      supervisor = PumaProcessSupervisor.instance
      supervisor.supervise(start_server.call) do
        Gitlab::AppLogger.info('Puma metrics server terminated, restarting...')
        start_server.call
      end
    end

    def start_for_sidekiq(**options)
      if new_metrics_server?
        self.spawn('sidekiq', **options)
      else
        self.fork('sidekiq', **options)
      end
    end

    def spawn(target, metrics_dir:, **options)
      return spawn_ruby_server(target, metrics_dir: metrics_dir, **options) unless new_metrics_server?

      name = settings_key(target)
      settings = ::Settings.monitoring[name]
      path = options[:path]&.then { |p| Pathname.new(p) } || Pathname.new('')
      cmd = path.join('gitlab-metrics-exporter').to_path
      env = {
        'GOGC' => '10', # Set Go GC heap goal to 10% to curb memory growth.
        'GME_MMAP_METRICS_DIR' => metrics_dir.to_s,
        'GME_PROBES' => 'self,mmap,mmap_stats',
        'GME_SERVER_HOST' => settings['address'],
        'GME_SERVER_PORT' => settings['port'].to_s
      }

      if settings['log_enabled']
        env['GME_LOG_FILE'] = File.join(Rails.root, 'log', "#{name}.log")
        env['GME_LOG_LEVEL'] = 'info'
      else
        env['GME_LOG_LEVEL'] = 'quiet'
      end

      if settings['tls_enabled']
        env['GME_CERT_FILE'] = settings['tls_cert_path']
        env['GME_CERT_KEY'] = settings['tls_key_path']
      end

      Process.spawn(env, cmd, err: $stderr, out: $stdout, pgroup: true).tap do |pid|
        Process.detach(pid)
      end
    end

    def spawn_ruby_server(target, metrics_dir:, wipe_metrics_dir: false, **options)
      ensure_valid_target!(target)

      cmd = "#{Rails.root}/bin/metrics-server"
      env = {
        'METRICS_SERVER_TARGET' => target,
        'WIPE_METRICS_DIR' => wipe_metrics_dir ? '1' : '0',
        'GITLAB_CONFIG' => ENV['GITLAB_CONFIG']
      }

      Process.spawn(env, cmd, err: $stderr, out: $stdout, pgroup: true).tap do |pid|
        Process.detach(pid)
      end
    end

    def fork(target, metrics_dir:, wipe_metrics_dir: false, reset_signals: [])
      ensure_valid_target!(target)

      pid = Process.fork

      if pid.nil? # nil means we're inside the fork
        # Remove any custom signal handlers the parent process had registered, since we do
        # not want to inherit them, and Ruby forks with a `clone` that has the `CLONE_SIGHAND`
        # flag set.
        Gitlab::ProcessManagement.modify_signals(reset_signals, 'DEFAULT')

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

    private

    def new_metrics_server?
      Gitlab::Utils.to_boolean(ENV['GITLAB_GOLANG_METRICS_SERVER'])
    end

    def ensure_valid_target!(target)
      raise "Target must be one of [puma,sidekiq]" unless %w(puma sidekiq).include?(target)
    end

    def settings_key(target)
      case target
      when 'puma' then 'web_exporter'
      when 'sidekiq' then 'sidekiq_exporter'
      else ensure_valid_target!(target)
      end
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
      config.pid_provider = proc { name }
    end

    FileUtils.mkdir_p(@metrics_dir, mode: 0700)
    ::Prometheus::CleanupMultiprocDirService.new(@metrics_dir).execute if @wipe_metrics_dir

    # We need to `warmup: true` since otherwise the sampler and exporter threads enter
    # a race where not all Prometheus db files will be visible to the exporter, resulting
    # in missing metrics.
    # Warming up ensures that these files exist prior to the exporter starting up.
    Gitlab::Metrics::Samplers::RubySampler.initialize_instance(prefix: name, warmup: true).start

    default_opts = { gc_requests: true, synchronous: true }
    exporter =
      case @target
      when 'puma'
        Gitlab::Metrics::Exporter::WebExporter.instance(**default_opts)
      when 'sidekiq'
        settings = Settings.new(Settings.monitoring[name])
        Gitlab::Metrics::Exporter::SidekiqExporter.instance(settings, **default_opts)
      end

    exporter.start
  end

  def name
    case @target
    when 'puma' then 'web_exporter'
    when 'sidekiq' then 'sidekiq_exporter'
    end
  end
end
