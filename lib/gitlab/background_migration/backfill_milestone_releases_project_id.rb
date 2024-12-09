# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMilestoneReleasesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_milestone_releases_project_id
      feature_category :release_orchestration

      class MilestoneRelease < ::ApplicationRecord
        self.table_name = :milestone_releases

        include EachBatch
      end

      def perform
        distinct_each_batch do |batch|
          milestone_ids = batch.pluck(batch_column)
          milestone_ids.each do |id|
            MilestoneRelease.where(milestone_id: id).each_batch(of: 100, column: :release_id) do |b|
              cte = Gitlab::SQL::CTE.new(:batched_relation, b.where(project_id: nil).limit(100))

              update_query = <<~SQL
                WITH #{cte.to_arel.to_sql}
                UPDATE milestone_releases
                SET project_id = releases.project_id
                FROM batched_relation
                INNER JOIN releases ON batched_relation.release_id = releases.id
                WHERE milestone_releases.milestone_id = batched_relation.milestone_id
              SQL

              connection.execute(update_query)
            end
          end
        end
      end
    end
  end
end
