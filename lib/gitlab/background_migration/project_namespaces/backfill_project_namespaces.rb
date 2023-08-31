# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module ProjectNamespaces
      # Back-fill project namespaces for projects that do not yet have a namespace.
      #
      # rubocop: disable Metrics/ClassLength
      class BackfillProjectNamespaces
        attr_accessor :project_ids, :sub_batch_size

        SUB_BATCH_SIZE = 25
        PROJECT_NAMESPACE_STI_NAME = 'Project'

        IsolatedModels = ::Gitlab::BackgroundMigration::ProjectNamespaces::Models

        def perform(start_id, end_id, migration_table_name, migration_column_name, sub_batch_size, pause_ms, namespace_id, migration_type = 'up')
          @sub_batch_size = sub_batch_size || SUB_BATCH_SIZE
          load_project_ids(start_id, end_id, namespace_id)

          case migration_type
          when 'up'
            backfill_project_namespaces
            mark_job_as_succeeded(start_id, end_id, namespace_id, 'up')
          when 'down'
            cleanup_backfilled_project_namespaces(namespace_id)
            mark_job_as_succeeded(start_id, end_id, namespace_id, 'down')
          else
            raise "Unknown migration type"
          end
        end

        def backfill_project_namespaces
          project_ids.each_slice(sub_batch_size) do |project_ids|
            # cleanup gin indexes on namespaces table
            cleanup_gin_index('namespaces')

            # cleanup gin indexes on projects table
            cleanup_gin_index('projects')

            # We need to lock these project records for the period when we create project namespaces
            # and link them to projects so that if a project is modified in the time between creating
            # project namespaces `batch_insert_namespaces` and linking them to projects `batch_update_projects`
            # we do not get them out of sync.
            #
            # see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72527#note_730679469
            Project.transaction do
              Project.where(id: project_ids).select(:id).lock!('FOR UPDATE').load

              batch_insert_namespaces(project_ids)
              batch_update_projects(project_ids)
              batch_update_project_namespaces_traversal_ids(project_ids)
            end
          end
        end

        def cleanup_gin_index(table_name)
          index_names = ApplicationRecord.connection.select_values("select indexname::text from pg_indexes where tablename = '#{table_name}' and indexdef ilike '%using gin%'")

          index_names.each do |index_name|
            ApplicationRecord.connection.execute("select gin_clean_pending_list('#{index_name}')")
          end
        end

        private

        def cleanup_backfilled_project_namespaces(namespace_id)
          project_ids.each_slice(sub_batch_size) do |project_ids|
            # IMPORTANT: first nullify project_namespace_id in projects table to avoid removing projects when records
            # from namespaces are deleted due to FK/triggers
            nullify_project_namespaces_in_projects(project_ids)
            delete_project_namespace_records(project_ids)
          end
        end

        def batch_insert_namespaces(project_ids)
          projects = IsolatedModels::Project.where(id: project_ids)
            .select("projects.id, projects.name, projects.path, projects.namespace_id, projects.visibility_level, shared_runners_enabled, '#{PROJECT_NAMESPACE_STI_NAME}', now(), now()")

          ApplicationRecord.connection.execute <<~SQL
            INSERT INTO namespaces (tmp_project_id, name, path, parent_id, visibility_level, shared_runners_enabled, type, created_at, updated_at)
            #{projects.to_sql}
            ON CONFLICT DO NOTHING;
          SQL
        end

        def batch_update_projects(project_ids)
          projects = IsolatedModels::Project.where(id: project_ids)
                       .joins("INNER JOIN namespaces ON projects.id = namespaces.tmp_project_id")
                       .select("namespaces.id, namespaces.tmp_project_id")

          ApplicationRecord.connection.execute <<~SQL
            WITH cte(project_namespace_id, project_id) AS MATERIALIZED (
              #{projects.to_sql}
            )
            UPDATE projects
            SET project_namespace_id = cte.project_namespace_id
            FROM cte
            WHERE id = cte.project_id AND projects.project_namespace_id IS DISTINCT FROM cte.project_namespace_id
          SQL
        end

        def batch_update_project_namespaces_traversal_ids(project_ids)
          namespaces = Namespace.where(tmp_project_id: project_ids)
                         .joins("INNER JOIN namespaces n2 ON namespaces.parent_id = n2.id")
                         .select("namespaces.id as project_namespace_id, n2.traversal_ids")

          # some customers have namespaces.id column type as bigint, which makes array_append(integer[], bigint) to fail
          # so we just explicitly cast arguments to compatible types
          ApplicationRecord.connection.execute <<~SQL
            UPDATE namespaces
            SET traversal_ids = array_append(project_namespaces.traversal_ids::bigint[], project_namespaces.project_namespace_id::bigint)
            FROM (#{namespaces.to_sql}) as project_namespaces(project_namespace_id, traversal_ids)
            WHERE id = project_namespaces.project_namespace_id
          SQL
        end

        def nullify_project_namespaces_in_projects(project_ids)
          IsolatedModels::Project.where(id: project_ids).update_all(project_namespace_id: nil)
        end

        def delete_project_namespace_records(project_ids)
          # keep the deletes a 10x smaller batch as deletes seem to be much more expensive
          delete_batch_size = (sub_batch_size / 10).to_i + 1

          project_ids.each_slice(delete_batch_size) do |p_ids|
            IsolatedModels::Namespace.where(type: PROJECT_NAMESPACE_STI_NAME).where(tmp_project_id: p_ids).delete_all
          end
        end

        def load_project_ids(start_id, end_id, namespace_id)
          projects = IsolatedModels::Project.arel_table
          relation = IsolatedModels::Project.where(projects[:id].between(start_id..end_id))
          relation = relation.where(projects[:namespace_id].in(Arel::Nodes::SqlLiteral.new(self.class.hierarchy_cte(namespace_id)))) if namespace_id

          @project_ids = relation.pluck(:id)
        end

        def mark_job_as_succeeded(*arguments)
          ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded('BackfillProjectNamespaces', arguments)
        end

        def self.hierarchy_cte(root_namespace_id)
          <<-SQL
              WITH RECURSIVE "base_and_descendants" AS (
                  (
                      SELECT "namespaces"."id"
                      FROM "namespaces"
                      WHERE "namespaces"."type" = 'Group' AND "namespaces"."id" = #{root_namespace_id.to_i}
                  )
                  UNION
                  (
                      SELECT "namespaces"."id"
                      FROM "namespaces", "base_and_descendants"
                      WHERE "namespaces"."type" = 'Group' AND "namespaces"."parent_id" = "base_and_descendants"."id"
                  )
              )
              SELECT "id" FROM "base_and_descendants" AS "namespaces"
          SQL
        end
      end
      # rubocop: enable Metrics/ClassLength
    end
  end
end
