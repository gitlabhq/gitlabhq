# frozen_string_literal: true

module Clusters
  module Applications
    class CheckInstallationProgressService < CheckProgressService
      private

      def operation_in_progress?
        app.installing? || app.updating?
      end

      def on_success
        app.make_installed!

        Gitlab::Tracking.event('cluster:applications', "cluster_application_#{app.name}_installed")
      ensure
        remove_installation_pod
      end

      def check_timeout
        if timed_out?
          begin
            app.make_errored!("Operation timed out. Check pod logs for #{pod_name} for more details.")
          end
        else
          ClusterWaitForAppInstallationWorker.perform_in(
            ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
        end
      end

      def pod_name
        install_command.pod_name
      end

      def timed_out?
        Time.now.utc - app.updated_at.utc > ClusterWaitForAppInstallationWorker::TIMEOUT
      end

      def remove_installation_pod
        helm_api.delete_pod!(pod_name)
      end
    end
  end
end
