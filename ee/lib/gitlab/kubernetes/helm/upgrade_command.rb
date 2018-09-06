require_dependency 'gitlab/kubernetes/helm.rb'

module Gitlab
  module Kubernetes
    module Helm
      class UpgradeCommand
        include BaseCommand

        attr_reader :name, :chart, :version, :repository, :files

        def initialize(name, chart:, files:, rbac:, version: nil, repository: nil)
          @name = name
          @chart = chart
          @rbac = rbac
          @version = version
          @files = files
          @repository = repository
        end

        def generate_script
          super + [
            init_command,
            repository_command,
            script_command
          ].compact.join("\n")
        end

        def rbac?
          @rbac
        end

        def pod_name
          "upgrade-#{name}"
        end

        private

        def init_command
          'helm init --client-only >/dev/null'
        end

        def repository_command
          "helm repo add #{name} #{repository}" if repository
        end

        def script_command
          upgrade_flags = "#{optional_version_flag}#{optional_tls_flags}" \
            " --reset-values" \
            " --install" \
            " --namespace #{::Gitlab::Kubernetes::Helm::NAMESPACE}" \
            " -f /data/helm/#{name}/config/values.yaml"

          "helm upgrade #{name} #{chart}#{upgrade_flags} >/dev/null\n"
        end

        def optional_version_flag
          " --version #{version}" if version
        end

        def optional_tls_flags
          return unless files.key?(:'ca.pem')

          " --tls" \
            " --tls-ca-cert #{files_dir}/ca.pem" \
            " --tls-cert #{files_dir}/cert.pem" \
            " --tls-key #{files_dir}/key.pem"
        end
      end
    end
  end
end
