# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProjectIdOnCiBuildNeeds < BatchedMigrationJob
      feature_category :continuous_integration

      operation_name :backfill_project_id_on_ci_build_needs
      scope_to ->(relation) { relation.where(project_id: nil) } # rubocop: disable Database/AvoidScopeTo -- `project_id` is an indexed column

      def construct_query(sub_batch:)
        <<~SQL
            UPDATE ci_build_needs
            SET project_id = p_ci_builds.project_id
            FROM p_ci_builds
            WHERE ci_build_needs.build_id = p_ci_builds.id
              AND ci_build_needs.id IN (#{sub_batch.select(:id).to_sql})
              AND p_ci_builds.partition_id = ci_build_needs.partition_id
        SQL
      end

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(construct_query(sub_batch: sub_batch))
        end
      end
    end
  end
end
