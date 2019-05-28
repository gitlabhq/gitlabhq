# frozen_string_literal: true

module Clusters
  module Applications
    class CheckInstallationProgressService < BaseHelmService
      def execute
        return unless operation_in_progress?

        case installation_phase
        when Gitlab::Kubernetes::Pod::SUCCEEDED
          on_success
        when Gitlab::Kubernetes::Pod::FAILED
          on_failed
        else
          check_timeout
        end
      rescue Kubeclient::HttpError => e
        log_error(e)

        app.make_errored!("Kubernetes error: #{e.error_code}")
      end

      private

      def operation_in_progress?
        app.installing? || app.updating?
      end

      def on_success
        app.make_installed!
      ensure
        remove_installation_pod
      end

      def on_failed
        app.make_errored!("Operation failed. Check pod logs for #{pod_name} for more details.")
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

      def installation_phase
        helm_api.status(pod_name)
      end

      def installation_errors
        helm_api.log(pod_name)
      end
    end
  end
end
