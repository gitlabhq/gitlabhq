# frozen_string_literal: true

module Clusters
  module Applications
    class InstallService < BaseHelmService
      def execute
        return unless app.scheduled?

        app.make_installing!
        log_event(:begin_install)
        helm_api.install(install_command)

        log_event(:schedule_wait_for_installation)
        ClusterWaitForAppInstallationWorker.perform_in(
          ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
      rescue Kubeclient::HttpError => e
        log_error(e)
        app.make_errored!("Kubernetes error: #{e.error_code}")
      rescue StandardError => e
        log_error(e)
        app.make_errored!("Can't start installation process.")
      end
    end
  end
end
