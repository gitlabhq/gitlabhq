# frozen_string_literal: true

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
          command = %w[helm init] + init_command_flags

          command.shelljoin
        end

        def init_command_flags
          tls_flags + optional_service_account_flag
        end

        def tls_flags
          [
            '--tiller-tls',
            '--tiller-tls-verify',
            '--tls-ca-cert', "#{files_dir}/ca.pem",
            '--tiller-tls-cert', "#{files_dir}/cert.pem",
            '--tiller-tls-key', "#{files_dir}/key.pem"
          ]
        end

        def optional_service_account_flag
          return [] unless rbac?

          ['--service-account', service_account_name]
        end
      end
    end
  end
end
