# frozen_string_literal: true

module Clusters
  module Applications
    class CheckUninstallProgressService < CheckProgressService
      private

      def operation_in_progress?
        app.uninstalling?
      end

      def on_success
        app.post_uninstall
        app.destroy!
      rescue StandardError => e
        app.make_errored!(_('Application uninstalled but failed to destroy: %{error_message}') % { error_message: e.message })
      ensure
        remove_uninstallation_pod
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

      def remove_uninstallation_pod
        helm_api.delete_pod!(pod_name)
      end
    end
  end
end
