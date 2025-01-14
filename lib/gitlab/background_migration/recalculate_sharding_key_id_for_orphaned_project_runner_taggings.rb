# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RecalculateShardingKeyIdForOrphanedProjectRunnerTaggings < BatchedMigrationJob
      operation_name :recalculate_sharding_key_id_on_project_runner_taggings
      feature_category :runner

      class CiRunnerTagging < ::Ci::ApplicationRecord
        self.table_name = :ci_runner_taggings
        self.primary_key = :id
      end

      class CiRunnerProject < ::Ci::ApplicationRecord
        self.table_name = :ci_runner_projects
        self.primary_key = :id
      end

      def perform
        distinct_each_batch do |sub_batch|
          runner_projects =
            CiRunnerProject.where("#{CiRunnerProject.table_name}.runner_id = #{CiRunnerTagging.table_name}.runner_id")
          runner_taggings_missing_owner_project =
            base_relation
              .where(runner_id: sub_batch.pluck(:runner_id))
              .where('NOT EXISTS (?)', # With a missing project connection
                runner_projects
                  .where("#{CiRunnerProject.table_name}.project_id = #{CiRunnerTagging.table_name}.sharding_key_id")
                  .select(1)
                  .limit(1)
              )
          # But with a fallback project connection
          runner_taggings_with_fallback_owner =
            runner_taggings_missing_owner_project.where('EXISTS(?)', runner_projects.select(1).limit(1))

          runner_taggings_with_fallback_owner.update_all <<~SQL
            sharding_key_id = (#{runner_projects.order(id: :asc).limit(1).select(:project_id).to_sql})
          SQL

          # NOTE: We don't need to delete orphaned runner taggings given that the runners will cascade the deletion
        end
      end

      private

      def base_relation
        define_batchable_model(batch_table, connection: connection, primary_key: :id)
          .where(batch_column => start_id..end_id)
          .where(runner_type: 3)
          .where.not(sharding_key_id: nil)
      end
    end
  end
end
