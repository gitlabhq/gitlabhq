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
          "helm init >/dev/null"
        end
      end
    end
  end
end
