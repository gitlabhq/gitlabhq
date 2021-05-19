# frozen_string_literal: true

module Clusters
  module Applications
    # Deprecated, to be removed in %14.0 as part of https://gitlab.com/groups/gitlab-org/-/epics/4280
    class PrometheusUpdateService < BaseHelmService
      attr_accessor :project

      def initialize(app, project)
        super(app)
        @project = project
      end

      def execute
        raise NotImplementedError, 'Externally installed prometheus should not be modified!' unless app.managed_prometheus?

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
