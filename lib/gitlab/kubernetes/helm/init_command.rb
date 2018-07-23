module Gitlab
  module Kubernetes
    module Helm
      class InitCommand
        include BaseCommand

        attr_reader :name, :config_files

        def initialize(name:, config_files:)
          @name = name
          @config_files = config_files
        end

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
