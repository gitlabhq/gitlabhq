module Gitlab
  module Kubernetes
    module Helm
      class KubectlCommand
        include BaseCommand

        attr_reader :name, :scripts, :files

        def initialize(name:, scripts:, files:)
          @name = name
          @files = files
          @rbac = false
          @scripts = scripts
        end

        def base_script
          <<~HEREDOC
            set -eo pipefail
            ALPINE_VERSION=$(cat /etc/alpine-release | cut -d '.' -f 1,2)
            echo http://mirror.clarkson.edu/alpine/v$ALPINE_VERSION/main >> /etc/apk/repositories
            echo http://mirror1.hs-esslingen.de/pub/Mirrors/alpine/v$ALPINE_VERSION/main >> /etc/apk/repositories
            apk add -U wget ca-certificates openssl >/dev/null
            wget -q https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/darwin/amd64/kubectl
            mv /usr/bin/
          HEREDOC
        end

        def generate_script
          (base_script + scripts).join("\n")
        end

        def rbac?
          @rbac
        end
      end
    end
  end
end
