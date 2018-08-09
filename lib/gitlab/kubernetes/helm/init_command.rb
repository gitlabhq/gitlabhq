module Gitlab
  module Kubernetes
    module Helm
      class InitCommand
        include BaseCommand

        attr_reader :name, :files

        def initialize(name:, files:)
          @name = name
          @files = files
        end

        def generate_script
          super + [
            init_helm_command
          ].join("\n")
        end

        private

        def init_helm_command
          tls_flags = "--tiller-tls" \
            " --tiller-tls-verify --tls-ca-cert #{files_dir}/ca.pem" \
            " --tiller-tls-cert #{files_dir}/cert.pem" \
            " --tiller-tls-key #{files_dir}/key.pem"

          "helm init #{tls_flags} >/dev/null"
        end
      end
    end
  end
end
