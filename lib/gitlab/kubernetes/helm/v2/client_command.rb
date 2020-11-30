# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module V2
        module ClientCommand
          def init_command
            <<~SHELL.chomp
              export HELM_HOST="localhost:44134"
              tiller -listen ${HELM_HOST} -alsologtostderr &
              helm init --client-only
            SHELL
          end

          def repository_command
            ['helm', 'repo', 'add', name, repository].shelljoin if repository
          end

          private

          def repository_update_command
            'helm repo update'
          end
        end
      end
    end
  end
end
