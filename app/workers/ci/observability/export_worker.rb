# frozen_string_literal: true

module Ci
  module Observability
    class ExportWorker # rubocop:disable Scalability/IdempotentWorker -- Export operations to external systems aren't idempotent
      include ApplicationWorker

      deduplicate :until_executed
      queue_namespace :pipeline_hooks
      worker_resource_boundary :cpu
      data_consistency :delayed
      sidekiq_options retry: 3
      sidekiq_options dead: false
      feature_category :observability
      urgency :low

      worker_has_external_dependencies!

      defer_on_database_health_signal :gitlab_main

      def perform(pipeline_id)
        pipeline = Ci::Pipeline.find_by_id(pipeline_id)
        return unless pipeline
        return if pipeline.user&.blocked?

        Ci::Observability::ExportService.new(pipeline).execute
      end
    end
  end
end
