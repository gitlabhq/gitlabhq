# frozen_string_literal: true

module Clusters
  module Applications
    class UninstallService < BaseHelmService
      def execute
        return unless app.scheduled?

        app.make_uninstalling!
        uninstall
      end

      private

      def uninstall
        helm_api.uninstall(app.uninstall_command)

        Clusters::Applications::WaitForUninstallAppWorker.perform_in(
          Clusters::Applications::WaitForUninstallAppWorker::INTERVAL, app.name, app.id)
      rescue Kubeclient::HttpError => e
        log_error(e)
        app.make_errored!("Kubernetes error: #{e.error_code}")
      rescue StandardError => e
        log_error(e)
        app.make_errored!('Failed to uninstall.')
      end
    end
  end
end
