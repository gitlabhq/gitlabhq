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

      def perform; end
    end
  end
end
