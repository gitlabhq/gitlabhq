# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RecalculateShardingKeyIdForOrphanedProjectRunners < BatchedMigrationJob
      operation_name :recalculate_sharding_key_id_on_project_runners
      scope_to ->(relation) { relation.where(runner_type: 3).where.not(sharding_key_id: nil) }
      feature_category :runner

      class CiRunner < ::Ci::ApplicationRecord
        self.table_name = :ci_runners
        self.primary_key = :id
      end

      class CiRunnerProject < ::Ci::ApplicationRecord
        self.table_name = :ci_runner_projects
        self.primary_key = :id
      end

      def perform
        runner_projects = CiRunnerProject.where("#{CiRunnerProject.table_name}.runner_id = #{CiRunner.table_name}.id")

        each_sub_batch do |sub_batch|
          runners_missing_owner_project =
            CiRunner.id_in(sub_batch.pluck(:id))
              .where_not_exists( # With a missing project connection
                runner_projects
                  .where("#{CiRunnerProject.table_name}.project_id = #{CiRunner.table_name}.sharding_key_id")
                  .limit(1)
              )
          # But with a fallback project connection
          runners_with_fallback_owner = runners_missing_owner_project.where_exists(runner_projects.limit(1))

          runners_with_fallback_owner.update_all <<~SQL
            sharding_key_id = (#{runner_projects.order(id: :asc).limit(1).select(:project_id).to_sql})
          SQL

          # Delete orphaned runners, cascading to runner managers, and runner taggings
          runners_missing_owner_project.delete_all
        end
      end
    end
  end
end
