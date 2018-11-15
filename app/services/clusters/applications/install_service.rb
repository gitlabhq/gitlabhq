# frozen_string_literal: true

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
        rescue Kubeclient::HttpError => e
          Rails.logger.error("Kubernetes error: #{e.error_code} #{e.message}")
          Gitlab::Sentry.track_acceptable_exception(e, extra: { scope: 'kubernetes', app_id: app.id })
          app.make_errored!("Kubernetes error: #{e.error_code}")
        rescue StandardError => e
          Rails.logger.error "Can't start installation process: #{e.class.name} #{e.message}"
          Gitlab::Sentry.track_acceptable_exception(e, extra: { scope: 'kubernetes', app_id: app.id })
          app.make_errored!("Can't start installation process.")
        end
      end
    end
  end
end
