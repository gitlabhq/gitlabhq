# frozen_string_literal: true

module Ci
  module JobArtifacts
    class DestroyAssociationsService
      BATCH_SIZE = 100

      def initialize(job_artifacts_relation)
        @job_artifacts_relation = job_artifacts_relation
        @statistics_updates = {}
      end

      def destroy_records
        @job_artifacts_relation.each_batch(of: BATCH_SIZE) do |relation|
          service = Ci::JobArtifacts::DestroyBatchService.new(relation, pick_up_at: Time.current)
          result  = service.execute(update_stats: false)
          @statistics_updates.merge!(result[:statistics_updates]) do |_project, existing_updates, new_updates|
            existing_updates.concat(new_updates)
          end
        end
      end

      def update_statistics
        @statistics_updates.each do |project, changes|
          ProjectStatistics.bulk_increment_statistic(project, Ci::JobArtifact.project_statistics_name, changes)
        end
      end
    end
  end
end
