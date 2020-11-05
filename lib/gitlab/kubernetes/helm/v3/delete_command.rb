# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module V3
        class DeleteCommand < BaseCommand
          attr_reader :predelete, :postdelete

          def initialize(predelete: nil, postdelete: nil, **args)
            super(**args)
            @predelete = predelete
            @postdelete = postdelete
          end

          def generate_script
            super + [
              predelete,
              delete_command,
              postdelete
            ].compact.join("\n")
          end

          def pod_name
            "uninstall-#{name}"
          end

          def delete_command
            ['helm', 'uninstall', name, *namespace_flag].shelljoin
          end
        end
      end
    end
  end
end
