module Gitlab
  module Kubernetes
    module Helm
      class InstallCommand < BaseCommand
        attr_reader :name, :chart, :version, :repository, :values

        def initialize(name, chart:, values:, version: nil, repository: nil)
          @name = name
          @chart = chart
          @version = version
          @values = values
          @repository = repository
        end

        def generate_script
          super + [
            init_command,
            repository_command,
            script_command
          ].compact.join("\n")
        end

        def config_map?
          true
        end

        def config_map_resource
          Gitlab::Kubernetes::ConfigMap.new(name, values).generate
        end

        private

        def init_command
          'helm init --client-only >/dev/null'
        end

        def repository_command
          "helm repo add #{name} #{repository}" if repository
        end

        def script_command
          <<~HEREDOC
          helm install #{chart} --name #{name}#{optional_version_flag} --namespace #{Gitlab::Kubernetes::Helm::NAMESPACE} -f /data/helm/#{name}/config/values.yaml >/dev/null
          HEREDOC
        end

        def optional_version_flag
          " --version #{version}" if version
        end
      end
    end
  end
end
