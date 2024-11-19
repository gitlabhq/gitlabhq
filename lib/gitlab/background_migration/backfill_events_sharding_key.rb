# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEventsShardingKey < BatchedMigrationJob
      feature_category :database
      operation_name :backfill_personal_namespace_id

      scope_to ->(relation) { relation.where(project_id: nil).order(:project_id) }

      SUB_BATCH_SIZE = 150

      def self.reset_order
        false
      end

      def perform
        each_sub_batch(batching_arguments: { reset_order: self.class.reset_order }) do |sub_batch|
          relation = sub_batch.select(:id, :group_id, :personal_namespace_id).limit(SUB_BATCH_SIZE)

          # Try to back-fill project_id / group_id from model
          backfill_from_model(relation)

          # Try to back-fill personal_namespace_id from author
          connection.execute(
            <<~SQL
              WITH relation AS MATERIALIZED (#{relation.to_sql}),
              filtered_relation AS MATERIALIZED (SELECT id FROM relation WHERE group_id IS NULL AND personal_namespace_id IS NULL LIMIT #{SUB_BATCH_SIZE})
              UPDATE events
              SET personal_namespace_id = namespaces.id
              FROM namespaces
              WHERE events.author_id = namespaces.owner_id AND namespaces.type = 'User'
              AND events.id IN (SELECT id FROM filtered_relation)
            SQL
          )

          # Delete records without sharding key
          connection.execute(
            <<~SQL
              WITH relation AS MATERIALIZED (#{relation.to_sql}),
              filtered_relation AS MATERIALIZED (SELECT id FROM relation WHERE group_id IS NULL AND personal_namespace_id IS NULL LIMIT #{SUB_BATCH_SIZE})
              DELETE FROM events USING filtered_relation WHERE events.id = filtered_relation.id
            SQL
          )
        end
      end

      private

      def backfill_from_model(relation)
        target_types_for_notes = "'DiffNote', 'DiscussionNote', 'IterationNote', 'LabelNote', " \
          "'LegacyDiffNote', 'MilestoneNote', 'Note', 'StateNote', 'SyntheticNote', 'WeightNote'"

        [
          ['project_id', 'notes', 'project_id', target_types_for_notes],
          ['project_id', 'merge_requests', 'target_project_id', "'MergeRequest'"],
          ['project_id', 'design_management_designs', 'project_id', "'DesignManagement::Design'"],
          ['project_id', 'issues', 'project_id', "'Issue', 'WorkItem'"],
          ['project_id', 'milestones', 'project_id', "'Milestone'"],
          ['project_id', 'wiki_page_meta', 'project_id', "'WikiPage::Meta'"],
          ['group_id', 'wiki_page_meta', 'namespace_id', "'WikiPage::Meta'"],
          ['group_id', 'epics', 'group_id', "'Epic'"]
        ].each do |target_column, source_table, source_column, target_types|
          connection.execute(
            <<~SQL
              WITH relation AS MATERIALIZED (#{relation.to_sql}),
              filtered_relation AS MATERIALIZED (SELECT id FROM relation WHERE group_id IS NULL AND personal_namespace_id IS NULL LIMIT #{SUB_BATCH_SIZE})
              UPDATE events
              SET #{target_column} = #{source_table}.#{source_column}
              FROM #{source_table}
              WHERE events.target_id = #{source_table}.id
                AND events.target_type IN (#{target_types})
                AND #{source_table}.#{source_column} IS NOT NULL
                AND events.id IN (SELECT id FROM filtered_relation)
            SQL
          )
        end
      end
    end
  end
end
