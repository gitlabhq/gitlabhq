# frozen_string_literal: true

module Clusters
  module Applications
    class InstallService < BaseHelmService
      def execute
        Gitlab::AppLogger.info('---- IN execute installing ----')
        return unless app.scheduled?

        begin
          
          app.make_installing!
          helm_api.install(install_command)

          ClusterWaitForAppInstallationWorker.perform_in(
            ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
        rescue Kubeclient::HttpError => e
          Gitlab::AppLogger.info('HttpError---- IN execute installing ----')
          Gitlab::AppLogger.error(e)
          Gitlab::AppLogger.error(e.backtrace.join("\n"))
          app.make_errored!("Kubernetes error.")
        rescue StandardError => e
          Gitlab::AppLogger.info('StandardError---- IN execute installing ----')
          Gitlab::AppLogger.error(e)
          Gitlab::AppLogger.error(e.backtrace.join("\n"))
          app.make_errored!("Can't start installation process.")
        end
      end
    end
  end
end
