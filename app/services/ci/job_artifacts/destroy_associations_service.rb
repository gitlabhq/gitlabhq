# frozen_string_literal: true

module Ci
  module JobArtifacts
    class DestroyAssociationsService
      BATCH_SIZE = 100

      def initialize(job_artifacts_relation)
        @job_artifacts_relation = job_artifacts_relation
        @statistics = {}
      end

      def destroy_records
        @job_artifacts_relation.each_batch(of: BATCH_SIZE) do |relation|
          service = Ci::JobArtifacts::DestroyBatchService.new(relation, pick_up_at: Time.current)
          result  = service.execute(update_stats: false)
          updates = result[:statistics_updates]

          @statistics.merge!(updates) { |_key, oldval, newval| newval + oldval }
        end
      end

      def update_statistics
        @statistics.each do |project, delta|
          project.increment_statistic_value(Ci::JobArtifact.project_statistics_name, delta)
        end
      end
    end
  end
end
