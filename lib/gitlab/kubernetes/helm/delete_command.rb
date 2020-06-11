# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
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
            wait_for_tiller_command,
            predelete,
            delete_command,
            postdelete
          ].compact.join("\n")
        end

        def pod_name
          "uninstall-#{name}"
        end

        def delete_command
          command = ['helm', 'delete', '--purge', name] + tls_flags_if_remote_tiller

          command.shelljoin
        end
      end
    end
  end
end
