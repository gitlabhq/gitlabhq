# frozen_string_literal: true

module Clusters
  module Applications
    class CheckInstallationProgressService < BaseHelmService
      def execute
        return unless app.installing?

        case installation_phase
        when Gitlab::Kubernetes::Pod::SUCCEEDED
          on_success
        when Gitlab::Kubernetes::Pod::FAILED
          on_failed
        else
          check_timeout
        end
      rescue Kubeclient::HttpError => ke
        app.make_errored!("Kubernetes error: #{ke.message}") unless app.errored?
      end

      private

      def on_success
        app.make_installed!
      ensure
        remove_installation_pod
        remove_config_map
      end

      def on_failed
        app.make_errored!(installation_errors || 'Installation silently failed')
      ensure
        remove_installation_pod
        remove_config_map
      end

      def check_timeout
        if timeouted?
          begin
            app.make_errored!('Installation timed out')
          ensure
            remove_installation_pod
            remove_config_map
          end
        else
          ClusterWaitForAppInstallationWorker.perform_in(
            ClusterWaitForAppInstallationWorker::INTERVAL, app.name, app.id)
        end
      end

      def timeouted?
        Time.now.utc - app.updated_at.to_time.utc > ClusterWaitForAppInstallationWorker::TIMEOUT
      end

      # FIXME Prometheus relies on config maps!
      def remove_config_map
        config_map_name = ::Gitlab::Kubernetes::ConfigMap.new(app.name, app.files).config_map_name
        helm_api.delete_config_map(config_map_name)
      end

      def remove_installation_pod
        helm_api.delete_pod!(install_command.pod_name)
      rescue
        # no-op
      end

      def installation_phase
        helm_api.status(install_command.pod_name)
      end

      def installation_errors
        helm_api.log(install_command.pod_name)
      end
    end
  end
end
