# frozen_string_literal: true

module Clusters
  module Applications
    class PatchService < BaseHelmService
      def execute
        return unless app.scheduled?

        app.make_updating!

        helm_api.update(update_command)

        ClusterWaitForAppInstallationWorker.perform_in(
          ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
      rescue Kubeclient::HttpError => e
        log_error(e)
        app.make_update_errored!("Kubernetes error: #{e.error_code}")
      rescue StandardError => e
        log_error(e)
        app.make_update_errored!("Can't start update process.")
      end
    end
  end
end
