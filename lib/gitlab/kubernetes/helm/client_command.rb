# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module ClientCommand
        def init_command
          # Here we are always upgrading to the latest version of Tiller when
          # installing an app. We ensure the helm version stored in the
          # database is correct by also updating this after transition to
          # :installed,:updated in Clusters::Concerns::ApplicationStatus
          'helm init --upgrade'
        end

        def wait_for_tiller_command
          helm_check = ['helm', 'version', *optional_tls_flags].shelljoin
          # This is necessary to give Tiller time to restart after upgrade.
          # Ideally we'd be able to use --wait but cannot because of
          # https://github.com/helm/helm/issues/4855
          "for i in $(seq 1 30); do #{helm_check} && break; sleep 1s; echo \"Retrying ($i)...\"; done"
        end

        def repository_command
          ['helm', 'repo', 'add', name, repository].shelljoin if repository
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
