# frozen_string_literal: true

module Clusters
  module Applications
    class BaseHelmService
      attr_accessor :app

      def initialize(app)
        @app = app
      end

      protected

      def log_error(error)
        meta = {
          exception: error.class.name,
          error_code: error.respond_to?(:error_code) ? error.error_code : nil,
          service: self.class.name,
          app_id: app.id,
          project_ids: app.cluster.project_ids,
          group_ids: app.cluster.group_ids,
          message: error.message
        }

        logger.error(meta)
        Gitlab::Sentry.track_acceptable_exception(error, extra: meta)
      end

      def logger
        @logger ||= Gitlab::Kubernetes::Logger.build
      end

      def cluster
        app.cluster
      end

      def kubeclient
        cluster.kubeclient
      end

      def helm_api
        @helm_api ||= Gitlab::Kubernetes::Helm::Api.new(kubeclient)
      end

      def install_command
        @install_command ||= app.install_command
      end

      def update_command
        @update_command ||= app.update_command
      end

      def upgrade_command(new_values = "")
        app.upgrade_command(new_values)
      end
    end
  end
end
