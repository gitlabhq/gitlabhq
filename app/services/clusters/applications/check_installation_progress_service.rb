module Clusters
  module Applications
    class CheckInstallationProgressService < BaseHelmService
      def execute
        return unless app.installing?

        case installation_phase
        when Gitlab::Kubernetes::Pod::SUCCEEDED
          on_succeeded
        when Gitlab::Kubernetes::Pod::FAILED
          on_failed
        else
          check_timeout
        end
      rescue KubeException => ke
        app.make_errored!("Kubernetes error: #{ke.message}") unless app.errored?
      end

      private

      def on_succeeded
        if app.make_installed
          finalize_installation
        else
          app.make_errored!("Failed to update app record; #{app.errors}")
        end
      end

      def on_failed
        app.make_errored!(log || 'Installation silently failed')
        finalize_installation
      end

      def check_timeout
        if Time.now.utc - app.updated_at.to_time.utc > ClusterWaitForAppInstallationWorker::TIMEOUT
          app.make_errored!('App installation timeouted')
        else
          ClusterWaitForAppInstallationWorker.perform_in(
            ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
        end
      end

      def finilize_installation
        FinalizeInstallationService.new(app).execute
      end

      def installation_phase
        helm_api.installation_status(app)
      end

      def installation_errors
        helm_api.installation_log(app)
      end
    end
  end
end
