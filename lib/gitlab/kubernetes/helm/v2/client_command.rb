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

          def optional_tls_flags
            return [] unless files.key?(:'ca.pem')

            [
              '--tls',
              '--tls-ca-cert', "#{files_dir}/ca.pem",
              '--tls-cert', "#{files_dir}/cert.pem",
              '--tls-key', "#{files_dir}/key.pem"
            ]
          end
        end
      end
    end
  end
end
