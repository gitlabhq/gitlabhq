# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will insert record into project_pages_metadata
    # for each existing project
    class MigratePagesMetadata
      def perform(start_id, stop_id)
        perform_on_relation(Project.where(id: start_id..stop_id))
      end

      def perform_on_relation(relation)
        successful_pages_deploy = <<~SQL
          SELECT TRUE
          FROM ci_builds
          WHERE ci_builds.type = 'GenericCommitStatus'
            AND ci_builds.status = 'success'
            AND ci_builds.stage = 'deploy'
            AND ci_builds.name = 'pages:deploy'
            AND ci_builds.project_id = projects.id
          LIMIT 1
        SQL

        select_from = relation
          .select("projects.id", "COALESCE((#{successful_pages_deploy}), FALSE)")
          .to_sql

        ActiveRecord::Base.connection_pool.with_connection do |connection|
          connection.execute <<~SQL
            INSERT INTO project_pages_metadata (project_id, deployed)
          #{select_from}
            ON CONFLICT (project_id) DO NOTHING
          SQL
        end
      end
    end
  end
end
