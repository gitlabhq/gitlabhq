# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Sets model_registry_access_level and model_experiments_access_level to PRIVATE on existing
    # non-public projects where they are currently ENABLED. This makes the Featurable access level
    # reproduce today's ProjectPolicy behaviour (member-only on non-public projects) before that
    # policy carve-out is removed. PRIVATE and DISABLED rows are left untouched.
    class BackfillModelFeaturesAccessLevel < BatchedMigrationJob
      # Featurable access levels. PUBLIC (30) is not a reachable state for these features.
      ENABLED = 20
      PRIVATE = 10
      # Gitlab::VisibilityLevel::PUBLIC
      PUBLIC_VISIBILITY = 20

      operation_name :backfill_model_features_access_level
      feature_category :mlops
      cursor :id

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            UPDATE project_features
            SET
              model_registry_access_level =
                CASE WHEN project_features.model_registry_access_level = #{ENABLED}
                     THEN #{PRIVATE}
                     ELSE project_features.model_registry_access_level
                END,
              model_experiments_access_level =
                CASE WHEN project_features.model_experiments_access_level = #{ENABLED}
                     THEN #{PRIVATE}
                     ELSE project_features.model_experiments_access_level
                END
            FROM projects
            WHERE project_features.id IN (#{sub_batch.select(:id).to_sql})
              AND projects.id = project_features.project_id
              AND projects.visibility_level <> #{PUBLIC_VISIBILITY}
              AND (
                project_features.model_registry_access_level = #{ENABLED}
                OR project_features.model_experiments_access_level = #{ENABLED}
              )
          SQL
        end
      end
    end
  end
end
