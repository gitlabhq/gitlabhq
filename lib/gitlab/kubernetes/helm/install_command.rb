module Gitlab
  module Kubernetes
    module Helm
      class InstallCommand
        attr_reader :name, :install_helm, :chart, :chart_values_file

        def initialize(name, install_helm: false, chart: false, chart_values_file: false)
          @name = name
          @install_helm = install_helm
          @chart = chart
          @chart_values_file = chart_values_file
        end

        def pod_name
          "install-#{name}"
        end

        def generate_script(namespace_name)
          [
            install_dps_command,
            init_command,
            complete_command(namespace_name)
          ].join("\n")
        end

        private

        def init_command
          if install_helm
            'helm init >/dev/null'
          else
            'helm init --client-only >/dev/null'
          end
        end

        def complete_command(namespace_name)
          return unless chart

          if chart_values_file
            "helm install #{chart} --name #{name} --namespace #{namespace_name} -f /data/helm/#{name}/config/values.yaml >/dev/null"
          else
            "helm install #{chart} --name #{name} --namespace #{namespace_name} >/dev/null"
          end
        end

        def install_dps_command
          <<~HEREDOC
            set -eo pipefail
            apk add -U ca-certificates openssl >/dev/null
            wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v#{Gitlab::Kubernetes::Helm::HELM_VERSION}-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
            mv /tmp/linux-amd64/helm /usr/bin/
          HEREDOC
        end
      end
    end
  end
end
