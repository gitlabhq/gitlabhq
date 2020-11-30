# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module V2
        class ResetCommand < BaseCommand
          include ClientCommand

          def generate_script
            super + [
              init_command,
              reset_helm_command
            ].join("\n")
          end

          def pod_name
            "uninstall-#{name}"
          end

          private

          def reset_helm_command
            'helm reset --force'
          end
        end
      end
    end
  end
end
