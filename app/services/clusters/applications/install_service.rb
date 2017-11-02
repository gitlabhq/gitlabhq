module Clusters
  module Applications
    class InstallService < BaseHelmService
      def execute
        return unless app.scheduled?

        begin
          helm_api.install(app)

          if app.make_installing
            ClusterWaitForAppInstallationWorker.perform_in(
              ClusterWaitForAppInstallationWorker::INITIAL_INTERVAL, app.name, app.id)
          else
            app.make_errored!("Failed to update app record; #{app.errors}")
          end
        rescue KubeException => ke
          app.make_errored!("Kubernetes error: #{ke.message}")
        rescue StandardError
          app.make_errored!("Can't start installation process")
        end
      end
    end
  end
end
