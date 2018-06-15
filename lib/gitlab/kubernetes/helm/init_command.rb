module Gitlab
  module Kubernetes
    module Helm
      class InitCommand < BaseCommand
        def generate_script
          super + [
            init_helm_command
          ].join("\n")
        end

        private

        def init_helm_command
          <<~CMD
            echo $CA_CERT | base64 -d > ca.cert.pem
            echo $TILLER_CERT | base64 -d > tiller.cert.pem
            echo $TILLER_KEY | base64 -d > tiller.key.pem
            helm init --tiller-tls --tiller-tls-cert ./tiller.cert.pem --tiller-tls-key ./tiller.key.pem --tiller-tls-verify --tls-ca-cert ca.cert.pem >/dev/null
          CMD
        end
      end
    end
  end
end
