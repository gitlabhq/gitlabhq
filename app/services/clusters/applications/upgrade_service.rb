# frozen_string_literal: true

module Clusters
  module Applications
    class UpgradeService < BaseHelmService
      def execute
        return unless app.scheduled?

        begin
          app.make_updating!

          log_event(:begin_upgrade)
          # install_command works with upgrades too
          # as it basically does `helm upgrade --install`
          helm_api.update(install_command)

          log_event(:schedule_wait_for_upgrade)
          ClusterWaitForAppInstallationWorker.perform_in(
            ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
        rescue Kubeclient::HttpError => e
          log_error(e)
          app.make_update_errored!("Kubernetes error: #{e.error_code}")
        rescue StandardError => e
          log_error(e)
          app.make_update_errored!("Can't start upgrade process.")
        end
      end
    end
  end
end
