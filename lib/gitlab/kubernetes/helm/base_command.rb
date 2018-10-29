module Gitlab
  module Kubernetes
    module Helm
      module BaseCommand
        def pod_resource
          pod_service_account_name = rbac? ? service_account_name : nil

          Gitlab::Kubernetes::Helm::Pod.new(self, namespace, service_account_name: pod_service_account_name).generate
        end

        def generate_script
          <<~HEREDOC
            set -eo pipefail
            ALPINE_VERSION=$(cat /etc/alpine-release | cut -d '.' -f 1,2)
            echo http://mirror.clarkson.edu/alpine/v$ALPINE_VERSION/main >> /etc/apk/repositories
            echo http://mirror1.hs-esslingen.de/pub/Mirrors/alpine/v$ALPINE_VERSION/main >> /etc/apk/repositories
            apk add -U wget ca-certificates openssl git >/dev/null
            wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v#{Gitlab::Kubernetes::Helm::HELM_VERSION}-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
            mv /tmp/linux-amd64/helm /usr/bin/

            wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
            wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk
            apk add glibc-2.28-r0.apk > /dev/null
            rm glibc-2.28-r0.apk
            wget -q https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/kubectl
            chmod +x kubectl
            mv kubectl /usr/bin/
          HEREDOC
        end

        def pod_name
          "install-#{name}"
        end

        def config_map_resource
          Gitlab::Kubernetes::ConfigMap.new(name, files).generate
        end

        def service_account_resource
          nil
        end

        def cluster_role_binding_resource
          nil
        end

        def file_names
          files.keys
        end

        def name
          raise "Not implemented"
        end

        def rbac?
          raise "Not implemented"
        end

        def files
          raise "Not implemented"
        end

        private

        def files_dir
          "/data/helm/#{name}/config"
        end

        def namespace
          Gitlab::Kubernetes::Helm::NAMESPACE
        end

        def service_account_name
          Gitlab::Kubernetes::Helm::SERVICE_ACCOUNT
        end
      end
    end
  end
end
