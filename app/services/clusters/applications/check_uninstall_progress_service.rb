# frozen_string_literal: true

module Clusters
  module Applications
    class CheckUninstallProgressService < BaseHelmService
      def execute
        return unless app.uninstalling?

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

        app.make_errored!(_('Kubernetes error: %{error_code}') % { error_code: e.error_code })
      end

      private

      def on_success
        app.post_uninstall
        app.destroy!
      rescue StandardError => e
        app.make_errored!(_('Application uninstalled but failed to destroy: %{error_message}') % { error_message: e.message })
      ensure
        remove_installation_pod
      end

      def on_failed
        app.make_errored!(_('Operation failed. Check pod logs for %{pod_name} for more details.') % { pod_name: pod_name })
      end

      def check_timeout
        if timed_out?
          app.make_errored!(_('Operation timed out. Check pod logs for %{pod_name} for more details.') % { pod_name: pod_name })
        else
          WaitForUninstallAppWorker.perform_in(WaitForUninstallAppWorker::INTERVAL, app.name, app.id)
        end
      end

      def pod_name
        app.uninstall_command.pod_name
      end

      def timed_out?
        Time.now.utc - app.updated_at.utc > WaitForUninstallAppWorker::TIMEOUT
      end

      def remove_installation_pod
        helm_api.delete_pod!(pod_name)
      end

      def installation_phase
        helm_api.status(pod_name)
      end
    end
  end
end
