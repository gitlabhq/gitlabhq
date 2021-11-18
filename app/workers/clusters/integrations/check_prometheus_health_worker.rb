# frozen_string_literal: true

module Clusters
  module Integrations
    class CheckPrometheusHealthWorker
      include ApplicationWorker

      data_consistency :always

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :incident_management
      urgency :low

      idempotent!
      worker_has_external_dependencies!

      def perform
        demo_project_ids = Gitlab::Monitor::DemoProjects.primary_keys

        clusters = Clusters::Cluster.with_integration_prometheus
          .with_project_http_integrations(demo_project_ids)

        # Move to a seperate worker with scoped context if expanded to do work on customer projects
        clusters.each { |cluster| Clusters::Integrations::PrometheusHealthCheckService.new(cluster).execute }
      end
    end
  end
end
