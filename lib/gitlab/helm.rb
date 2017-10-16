module Gitlab
  class Helm
    Error = Class.new(StandardError)

    attr_accessor :namespace
    attr_accessor :logger

    delegate :debug, :debug?, to: :logger, allow_nil: true

    def initialize(namespace, kubeconfig, logger: nil)
      self.namespace = namespace
      self.logger = logger
      @kubeconfig = kubeconfig
    end

    def init!
      prepare_env do |env|
        helm('init', '--upgrade', env: env)
      end
    end

    def install_or_upgrade!(app_name, chart)
      prepare_env do |env|
        helm('init', '--client-only', env: env)
        helm('upgrade', '--install', '--namespace', namespace, app_name, chart, env: env)
      end
    end

    private

    def prepare_env(*args, &blk)
      Dir.mktmpdir(['helm', namespace]) do |tmpdir|
        kubeconfig_path = File.join(tmpdir, 'kubeconfig')
        env = {
           'HELM_HOME' => File.join(tmpdir, 'helm'),
           'TILLER_NAMESPACE' => namespace,
           'KUBECONFIG' => kubeconfig_path
        }

        File.open(kubeconfig_path, 'w') { |c| c << YAML.dump(@kubeconfig) }

        debug("HELM: Running in tmpdir #{tmpdir}")
        yield(env) if block_given?
      end
    end

    def helm(*args, env: {})
      Open3.popen3(env, 'helm', *args) do |_, stdout, stderr, wait_thr|
        exit_status = wait_thr.value

        stdout.readlines.each { |l| debug("HELM: #{l.chomp}") } if debug?

        raise Error, stderr.read.chomp unless exit_status.success?
      end
    end
  end
end
