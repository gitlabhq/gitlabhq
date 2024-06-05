# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWorkItemHierarchyForEpics < BatchedMigrationJob
      feature_category :team_planning
      operation_name :backfill_work_item_hierarchy_for_epics

      class Epics < ApplicationRecord
        self.table_name = 'epics'
        self.inheritance_column = :_type_disabled
      end

      class WorkItemParentLinks < ApplicationRecord
        self.table_name = 'work_item_parent_links'
        self.inheritance_column = :_type_disabled
      end

      def perform
        each_sub_batch do |sub_batch|
          backfill_work_item_parent_links(sub_batch)
        end
      end

      private

      def backfill_work_item_parent_links(sub_batch)
        Epics.transaction do
          # prevent an epic being updated while we sync its data to work_item_parent_links table.
          # Wrap the locking into a transaction so that locks are kept for the duration of transaction.
          parents_and_children_batch =
            sub_batch
              .joins("INNER JOIN epics parent_epics ON epics.parent_id = parent_epics.id")
              .joins("INNER JOIN issues ON parent_epics.issue_id = issues.id")
              .select(
                <<-SQL
                  epics.issue_id AS child_id,
                  epics.relative_position,
                  parent_epics.issue_id AS parent_id,
                  issues.namespace_id as namespace_id
                SQL
              ).lock!('FOR UPDATE').load

          parent_links = build_relationship(parents_and_children_batch)
          WorkItemParentLinks.upsert_all(parent_links, unique_by: :work_item_id) unless parent_links.blank?
        end
      end

      def build_relationship(parents_and_children_batch)
        # Use current time for timestamps because there is no way
        # to know when epics.parent_id "(created|updated)_at" was set
        timestamp = Time.current

        parents_and_children_batch.flat_map do |child_and_parent_data|
          {
            work_item_id: child_and_parent_data['child_id'],
            work_item_parent_id: child_and_parent_data['parent_id'],
            relative_position: child_and_parent_data['relative_position'],
            namespace_id: child_and_parent_data['namespace_id'],
            created_at: timestamp,
            updated_at: timestamp
          }
        end
      end
    end
  end
end
