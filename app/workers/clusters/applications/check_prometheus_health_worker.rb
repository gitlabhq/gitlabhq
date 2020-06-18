# frozen_string_literal: true

module Clusters
  module Applications
    class CheckPrometheusHealthWorker
      include ApplicationWorker
      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      queue_namespace :incident_management
      feature_category :incident_management
      urgency :low

      idempotent!
      worker_has_external_dependencies!

      def perform
        demo_project_ids = Gitlab::Monitor::DemoProjects.primary_keys

        clusters = Clusters::Cluster.with_application_prometheus
          .with_project_alert_service_data(demo_project_ids)

        # Move to a seperate worker with scoped context if expanded to do work on customer projects
        clusters.each { |cluster| Clusters::Applications::PrometheusHealthCheckService.new(cluster).execute }
      end
    end
  end
end
