# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class populates missing dismissal information for
    # vulnerability entries.
    class PopulateHasVulnerabilities
      class ProjectSetting < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'project_settings'

        def self.upsert_for(project_ids)
          connection.execute(upsert_sql % { project_ids: project_ids.join(', ') })
        end

        def self.upsert_sql
          <<~SQL
            WITH upsert_data (project_id, has_vulnerabilities, created_at, updated_at) AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
              SELECT projects.id, true, current_timestamp, current_timestamp FROM projects WHERE projects.id IN (%{project_ids})
            )
            INSERT INTO project_settings
            (project_id, has_vulnerabilities, created_at, updated_at)
            (SELECT * FROM upsert_data)
            ON CONFLICT (project_id)
            DO UPDATE SET
              has_vulnerabilities = true,
              updated_at = EXCLUDED.updated_at
          SQL
        end
      end

      class Vulnerability < ActiveRecord::Base # rubocop:disable Style/Documentation
        include EachBatch

        self.table_name = 'vulnerabilities'
      end

      def perform(*project_ids)
        ProjectSetting.upsert_for(project_ids)
      rescue StandardError => e
        log_error(e, project_ids)
      ensure
        log_info(project_ids)
      end

      private

      def log_error(error, project_ids)
        ::Gitlab::BackgroundMigration::Logger.error(
          migrator: self.class.name,
          message: error.message,
          project_ids: project_ids
        )
      end

      def log_info(project_ids)
        ::Gitlab::BackgroundMigration::Logger.info(
          migrator: self.class.name,
          message: 'Projects has been processed to populate `has_vulnerabilities` information',
          count: project_ids.length
        )
      end
    end
  end
end
