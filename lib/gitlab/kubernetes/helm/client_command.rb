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
          # This is necessary to give Tiller time to restart after upgrade.
          # Ideally we'd be able to use --wait but cannot because of
          # https://github.com/helm/helm/issues/4855
          'for i in $(seq 1 30); do helm version && break; sleep 1s; echo "Retrying ($i)..."; done'
        end

        def repository_command
          ['helm', 'repo', 'add', name, repository].shelljoin if repository
        end
      end
    end
  end
end
