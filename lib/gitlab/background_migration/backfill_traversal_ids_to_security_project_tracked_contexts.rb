# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillTraversalIdsToSecurityProjectTrackedContexts < BatchedMigrationJob
      operation_name :backfill_traversal_ids_in_security_project_tracked_contexts_table
      feature_category :vulnerability_management

      # Compare-and-set: each row is written only while it still holds the value read from it at
      # pluck time. The transfer sync path writes the same column, so a row it moved in the window
      # between that read and this statement no longer matches and is left alone.
      UPDATE_SQL = <<~SQL
      WITH tracked_context_updates (id, expected_traversal_ids, traversal_ids) AS (
          %{with_values}
      )
        UPDATE
          security_project_tracked_contexts
        SET
          traversal_ids = tracked_context_updates.traversal_ids
        FROM
          tracked_context_updates
        WHERE
          tracked_context_updates.id = security_project_tracked_contexts.id AND
          security_project_tracked_contexts.traversal_ids = tracked_context_updates.expected_traversal_ids
      SQL

      def perform
        each_sub_batch do |sub_batch|
          # rubocop:disable CodeReuse/ActiveRecord -- specific for this backfill
          tracked_contexts = sub_batch.pluck(:id, :project_id, :traversal_ids)
          # rubocop:enable CodeReuse/ActiveRecord
          next if tracked_contexts.blank?

          values_sql = tracked_contexts_to_values_sql(tracked_contexts)

          next if values_sql.blank?

          ::SecApplicationRecord.connection.execute(update_sql(values_sql))
        end
      end

      private

      class Namespace < ::ApplicationRecord
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled
      end

      class Project < ::ApplicationRecord
        self.table_name = 'projects'

        belongs_to :namespace,
          class_name: '::Gitlab::BackgroundMigration::BackfillTraversalIdsToSecurityProjectTrackedContexts::Namespace'

        scope :joins_namespace, -> { joins(:namespace) }
        # rubocop: disable CodeReuse/ActiveRecord -- redefining to avoid using application code in migration
        scope :traversal_ids_by_project, ->(project_ids) {
          where(id: project_ids).joins_namespace.limit(project_ids.length)
                                .pluck(:id, :traversal_ids)
        }
        # rubocop: enable CodeReuse/ActiveRecord
      end

      # Rows already holding the correct value are dropped here rather than in the statement, so
      # they never reach the CTE and cost nothing to skip.
      def tracked_contexts_to_values_sql(tracked_contexts)
        project_ids = tracked_contexts.map { |_id, project_id| project_id }.uniq
        traversal_ids_by_project = Project.traversal_ids_by_project(project_ids).to_h

        return if traversal_ids_by_project.blank?

        values = tracked_contexts.filter_map do |id, project_id, tracked_context_traversal_ids|
          project_traversal_ids = traversal_ids_by_project[project_id]
          next if project_traversal_ids.nil? || project_traversal_ids == tracked_context_traversal_ids

          [
            Integer(id),
            Arel.sql("ARRAY#{tracked_context_traversal_ids}::bigint[]"),
            Arel.sql("ARRAY#{project_traversal_ids}::bigint[]")
          ]
        end

        return if values.empty?

        Arel::Nodes::ValuesList.new(values).to_sql
      end

      def update_sql(with_tracked_context_information)
        format(UPDATE_SQL, with_values: with_tracked_context_information)
      end
    end
  end
end
