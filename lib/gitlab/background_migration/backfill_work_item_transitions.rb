# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWorkItemTransitions < BatchedMigrationJob
      operation_name :backfill_work_item_transitions
      feature_category :team_planning

      class WorkItemTransition < ::ApplicationRecord
        self.table_name = 'work_item_transitions'
      end

      def perform
        each_sub_batch do |sub_batch|
          next if sub_batch.empty?

          backfill_work_item_transitions_for_batch(sub_batch)
        end
      end

      private

      def backfill_work_item_transitions_for_batch(issues_batch)
        records = issues_batch.pluck(
          :id, :namespace_id, :moved_to_id, :duplicated_to_id, :promoted_to_epic_id
        ).map do |id, namespace_id, moved_to_id, duplicated_to_id, promoted_to_epic_id|
          {
            work_item_id: id,
            namespace_id: namespace_id,
            moved_to_id: moved_to_id,
            duplicated_to_id: duplicated_to_id,
            promoted_to_epic_id: promoted_to_epic_id
          }
        end

        WorkItemTransition.upsert_all(records, on_duplicate: :skip, unique_by: :work_item_id)
      end
    end
  end
end
