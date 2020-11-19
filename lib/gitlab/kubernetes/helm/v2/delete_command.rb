# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module V2
        class DeleteCommand < BaseCommand
          include ClientCommand

          attr_reader :predelete, :postdelete

          def initialize(predelete: nil, postdelete: nil, **args)
            super(**args)
            @predelete = predelete
            @postdelete = postdelete
          end

          def generate_script
            super + [
              init_command,
              predelete,
              delete_command,
              postdelete
            ].compact.join("\n")
          end

          def pod_name
            "uninstall-#{name}"
          end

          def delete_command
            ['helm', 'delete', '--purge', name].shelljoin
          end
        end
      end
    end
  end
end
