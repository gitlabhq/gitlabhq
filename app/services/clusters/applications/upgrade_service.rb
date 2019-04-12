# frozen_string_literal: true

module Clusters
  module Applications
    class UpgradeService < BaseHelmService
      def execute
        return unless app.scheduled?

        app.make_updating!

        upgrade
      end

      private

      def upgrade
        # install_command works with upgrades too
        # as it basically does `helm upgrade --install`
        log_event(:begin_upgrade)
        helm_api.update(install_command)

        log_event(:schedule_wait_for_upgrade)
        ClusterWaitForAppInstallationWorker.perform_in(
          ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
      rescue Kubeclient::HttpError => e
        log_error(e)
        app.make_errored!("Kubernetes error: #{e.error_code}")
      rescue StandardError => e
        log_error(e)
        app.make_errored!('Failed to upgrade.')
      end
    end
  end
end
