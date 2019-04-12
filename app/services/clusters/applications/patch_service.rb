# frozen_string_literal: true

module Clusters
  module Applications
    class PatchService < BaseHelmService
      def execute
        return unless app.scheduled?

        app.make_updating!

        patch
      end

      private

      def patch
        log_event(:begin_patch)
        helm_api.update(update_command)

        log_event(:schedule_wait_for_patch)
        ClusterWaitForAppInstallationWorker.perform_in(
          ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
      rescue Kubeclient::HttpError => e
        log_error(e)
        app.make_errored!("Kubernetes error: #{e.error_code}")
      rescue StandardError => e
        log_error(e)
        app.make_errored!('Failed to update.')
      end
    end
  end
end
