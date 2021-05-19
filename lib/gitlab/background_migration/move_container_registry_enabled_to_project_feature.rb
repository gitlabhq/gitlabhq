# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration moves projects.container_registry_enabled values to
    # project_features.container_registry_access_level for the projects within
    # the given range of ids.
    class MoveContainerRegistryEnabledToProjectFeature
      MAX_BATCH_SIZE = 300

      ENABLED = 20
      DISABLED = 0

      def perform(from_id, to_id)
        (from_id..to_id).each_slice(MAX_BATCH_SIZE) do |batch|
          process_batch(batch.first, batch.last)
        end

        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded('MoveContainerRegistryEnabledToProjectFeature', [from_id, to_id])
      end

      private

      def process_batch(from_id, to_id)
        ActiveRecord::Base.connection.execute(update_sql(from_id, to_id))

        logger.info(message: "#{self.class}: Copied container_registry_enabled values for projects with IDs between #{from_id}..#{to_id}")
      end

      # For projects that have a project_feature:
      # Set project_features.container_registry_access_level to ENABLED (20) or DISABLED (0)
      #   depending if container_registry_enabled is true or false.
      def update_sql(from_id, to_id)
        <<~SQL
        UPDATE project_features
        SET container_registry_access_level = (CASE p.container_registry_enabled
                                              WHEN true THEN #{ENABLED}
                                              WHEN false THEN #{DISABLED}
                                              ELSE #{DISABLED}
                                              END)
        FROM projects p
        WHERE project_id = p.id AND
        project_id BETWEEN #{from_id} AND #{to_id}
        SQL
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
