# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Fix project name duplicates and backfill missing project namespace ids
    class FixDuplicateProjectNameAndPath
      SUB_BATCH_SIZE = 10
      # isolated project active record
      class Project < ActiveRecord::Base
        include ::EachBatch

        self.table_name = 'projects'

        scope :without_project_namespace, -> { where(project_namespace_id: nil) }
        scope :id_in, ->(ids) { where(id: ids) }
      end

      def perform(start_id, end_id)
        @project_ids = fetch_project_ids(start_id, end_id)
        backfill_project_namespaces_service = init_backfill_service(project_ids)
        backfill_project_namespaces_service.cleanup_gin_index('projects')

        project_ids.each_slice(SUB_BATCH_SIZE) do |ids|
          ApplicationRecord.connection.execute(update_projects_name_and_path_sql(ids))
        end

        backfill_project_namespaces_service.backfill_project_namespaces

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      attr_accessor :project_ids

      def fetch_project_ids(start_id, end_id)
        Project.without_project_namespace.where(id: start_id..end_id)
      end

      def init_backfill_service(project_ids)
        service = Gitlab::BackgroundMigration::ProjectNamespaces::BackfillProjectNamespaces.new
        service.project_ids = project_ids
        service.sub_batch_size = SUB_BATCH_SIZE

        service
      end

      def update_projects_name_and_path_sql(project_ids)
        <<~SQL
          WITH cte (project_id, path_from_route ) AS (
            #{path_from_route_sql(project_ids).to_sql}
          )
          UPDATE
              projects
          SET
              name = concat(projects.name, '-', id),
              path = CASE 
                         WHEN projects.path <> cte.path_from_route THEN path_from_route
                         ELSE projects.path
                     END
          FROM
              cte
          WHERE
              projects.id = cte.project_id;
        SQL
      end

      def path_from_route_sql(project_ids)
        Project.without_project_namespace.id_in(project_ids)
          .joins("INNER JOIN routes ON routes.source_id = projects.id AND routes.source_type = 'Project'")
          .select("projects.id, SUBSTRING(routes.path FROM '[^/]+(?=/$|$)') AS path_from_route")
      end

      def mark_job_as_succeeded(*arguments)
        ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'FixDuplicateProjectNameAndPath',
          arguments
        )
      end
    end
  end
end
