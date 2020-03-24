# frozen_string_literal: true

module Clusters
  module Applications
    class PrometheusUpdateService < BaseHelmService
      attr_accessor :project

      def initialize(app, project)
        super(app)
        @project = project
      end

      def execute
        app.make_updating!

        helm_api.update(patch_command(values))

        ::ClusterWaitForAppUpdateWorker.perform_in(::ClusterWaitForAppUpdateWorker::INTERVAL, app.name, app.id)
      rescue ::Kubeclient::HttpError => ke
        app.make_update_errored!("Kubernetes error: #{ke.message}")
      rescue StandardError => e
        app.make_update_errored!(e.message)
      end

      private

      def values
        PrometheusConfigService
          .new(project, cluster, app)
          .execute
          .to_yaml
      end
    end
  end
end
