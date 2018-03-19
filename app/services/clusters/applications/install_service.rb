module Clusters
  module Applications
    class InstallService < BaseHelmService
      def execute
        return unless app.scheduled?

        begin
          app.make_installing!
          helm_api.install(install_command)

          ClusterWaitForAppInstallationWorker.perform_in(
            ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
        rescue Kubeclient::HttpError => ke
          app.make_errored!("Kubernetes error: #{ke.message}")
        rescue StandardError
          app.make_errored!("Can't start installation process")
        end
      end
    end
  end
end
