# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      module ClientCommand
        def init_command
          if local_tiller_enabled?
            <<~HEREDOC.chomp
            export HELM_HOST="localhost:44134"
            tiller -listen ${HELM_HOST} -alsologtostderr &
            helm init --client-only
            HEREDOC
          else
            # Here we are always upgrading to the latest version of Tiller when
            # installing an app. We ensure the helm version stored in the
            # database is correct by also updating this after transition to
            # :installed,:updated in Clusters::Concerns::ApplicationStatus
            'helm init --upgrade'
          end
        end

        def wait_for_tiller_command
          return if local_tiller_enabled?

          helm_check = ['helm', 'version', *optional_tls_flags].shelljoin
          # This is necessary to give Tiller time to restart after upgrade.
          # Ideally we'd be able to use --wait but cannot because of
          # https://github.com/helm/helm/issues/4855

          "for i in $(seq 1 30); do #{helm_check} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)"
        end

        def repository_command
          ['helm', 'repo', 'add', name, repository].shelljoin if repository
        end

        private

        def tls_flags_if_remote_tiller
          return [] if local_tiller_enabled?

          optional_tls_flags
        end

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

        def local_tiller_enabled?
          Feature.enabled?(:managed_apps_local_tiller)
        end
      end
    end
  end
end
