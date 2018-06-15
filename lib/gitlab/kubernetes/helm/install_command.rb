module Gitlab
  module Kubernetes
    module Helm
      class InstallCommand < BaseCommand
        attr_reader :name, :chart, :repository, :values

        def generate_script
          super + [
            configure_certs_command,
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

        def configure_certs_command
          <<~CMD
          mkdir $(helm home)
          echo $CA_CERT | base64 -d > $(helm home)/ca.pem
          echo $HELM_CERT | base64 -d > $(helm home)/cert.pem
          echo $HELM_KEY | base64 -d > $(helm home)/key.pem
          CMD
        end

        def init_command
          'helm init --client-only >/dev/null'
        end

        def repository_command
          "helm repo add #{name} #{repository}" if repository
        end

        def script_command
          <<~HEREDOC
          helm install #{chart} --name #{name} --namespace #{Gitlab::Kubernetes::Helm::NAMESPACE} -f /data/helm/#{name}/config/values.yaml >/dev/null
          HEREDOC
        end
      end
    end
  end
end
