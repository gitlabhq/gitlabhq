# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Migrates internal_ids records for `usage: issues` from project to namespace scope.
    # For project issues it will be project namespace, for group issues it will be group namespace.
    class IssuesInternalIdScopeUpdater < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      operation_name :issues_internal_id_scope_updater
      feature_category :database

      ISSUES_USAGE = 0 # see Enums::InternalId#usage_resources[:issues]

      scope_to ->(relation) do
        relation.where(usage: ISSUES_USAGE).where.not(project_id: nil)
      end

      def perform
        each_sub_batch do |sub_batch|
          create_namespace_scoped_records(sub_batch)
          delete_project_scoped_records(sub_batch)
        end
      end

      private

      def delete_project_scoped_records(sub_batch)
        # There is no need to keep the project scoped issues usage as we move to scoping issues to namespace.
        # Also in case we do decide to move back to scoping issues usage to project, we are better off if the
        # project record is not present as that would result in overlapping IIDs because project scoped issues
        # usage will have outdated IIDs left in the DB
        log_info("Deleted internal_ids records", ids: sub_batch.pluck(:id))

        connection.execute(
          <<~SQL
            DELETE FROM internal_ids WHERE id IN (#{sub_batch.select(:id).to_sql})
          SQL
        )
      end

      def create_namespace_scoped_records(sub_batch)
        # Creates a corresponding namespace scoped record for every `issues` usage scoped to a project.
        # On conflict it means the record was already created when a new issue is created with the
        # newly namespace scoped Issue model, see Issue#has_internal_id definition. In which case to
        # make sure we have the namespace_id scoped record set to the greatest of the two last_values.
        created_records_ids = connection.execute(
          <<~SQL
              INSERT INTO internal_ids (usage, last_value, namespace_id)
                SELECT #{ISSUES_USAGE}, last_value, project_namespace_id
                FROM internal_ids
                INNER JOIN projects ON projects.id = internal_ids.project_id
                WHERE internal_ids.id IN(#{sub_batch.select(:id).to_sql})
              ON CONFLICT (usage, namespace_id) WHERE namespace_id IS NOT NULL
              DO UPDATE SET last_value = GREATEST(EXCLUDED.last_value, internal_ids.last_value)
              RETURNING id;
          SQL
        )

        log_info("Created/updated internal_ids records", ids: created_records_ids.field_values('id'))
      end

      def log_info(message, **extra)
        ::Gitlab::BackgroundMigration::Logger.info(migrator: self.class.to_s, message: message, **extra)
      end
    end
  end
end
