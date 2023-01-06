# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill projectfeatures.package_registry_access_level depending on projects.packages_enabled
    class BackfillProjectFeaturePackageRegistryAccessLevel < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      FEATURE_DISABLED = 0  # ProjectFeature::DISABLED
      FEATURE_PRIVATE = 10  # ProjectFeature::PRIVATE
      FEATURE_ENABLED = 20  # ProjectFeature::ENABLED
      FEATURE_PUBLIC = 30   # ProjectFeature::PUBLIC
      PROJECT_PRIVATE = 0   # Gitlab::VisibilityLevel::PRIVATE
      PROJECT_INTERNAL = 10 # Gitlab::VisibilityLevel::INTERNAL
      PROJECT_PUBLIC = 20   # Gitlab::VisibilityLevel::PUBLIC

      # Migration only version of ProjectFeature table
      class ProjectFeature < ::ApplicationRecord
        self.table_name = 'project_features'
      end

      operation_name :update_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          ProjectFeature.connection.execute(
            <<~SQL
            UPDATE project_features pf
            SET package_registry_access_level = (CASE p.packages_enabled
                                                  WHEN true THEN (CASE p.visibility_level
                                                                  WHEN #{PROJECT_PUBLIC} THEN #{FEATURE_PUBLIC}
                                                                  WHEN #{PROJECT_INTERNAL} THEN #{FEATURE_ENABLED}
                                                                  WHEN #{PROJECT_PRIVATE} THEN #{FEATURE_PRIVATE}
                                                                  END)
                                                  WHEN false THEN #{FEATURE_DISABLED}
                                                  ELSE #{FEATURE_DISABLED}
                                                  END)
            FROM projects p
            WHERE pf.project_id = p.id AND
            pf.project_id BETWEEN #{start_id} AND #{end_id}
            SQL
          )
        end
      end
    end
  end
end
