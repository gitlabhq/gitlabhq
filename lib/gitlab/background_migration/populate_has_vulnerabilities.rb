# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class populates missing dismissal information for
    # vulnerability entries.
    class PopulateHasVulnerabilities
      class ProjectSetting < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'project_settings'

        UPSERT_SQL = <<~SQL
          INSERT INTO project_settings
          (project_id, has_vulnerabilities, created_at, updated_at)
          VALUES
          %{values}
          ON CONFLICT (project_id)
          DO UPDATE SET
            has_vulnerabilities = true,
            updated_at = EXCLUDED.updated_at
        SQL

        def self.upsert_for(project_ids)
          timestamp = connection.quote(Time.now)
          values = project_ids.map { |project_id| "(#{project_id}, true, #{timestamp}, #{timestamp})" }.join(', ')

          connection.execute(UPSERT_SQL % { values: values })
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
