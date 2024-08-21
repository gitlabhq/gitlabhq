# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixSyncedEpicWorkItemParentLinks < BatchedMigrationJob
      operation_name :fix_synced_epic_work_item_parent_links
      feature_category :team_planning

      class EpicIssues < ApplicationRecord
        self.table_name = 'epic_issues'
        self.inheritance_column = :_type_disabled
      end

      class WorkItemParentLinks < ApplicationRecord
        self.table_name = 'work_item_parent_links'
        self.inheritance_column = :_type_disabled
      end

      class WorkItemType < ApplicationRecord
        self.table_name = 'work_item_types'
        self.inheritance_column = :_type_disabled
      end

      def perform
        each_sub_batch do |sub_batch|
          ApplicationRecord.transaction do
            WorkItemParentLinks.where(id: orphaned_work_item_parent_links(sub_batch).select(:id)).delete_all
          end

          ApplicationRecord.transaction do
            work_item_parent_links_to_create = missing_work_item_parent_links(sub_batch)
            WorkItemParentLinks.insert_all(work_item_parent_links_to_create) if work_item_parent_links_to_create.any?
          end
        end
      end

      # WorkItemParentLinks that do not exist because we did not update the reference from the old issue_id to the
      # new one.
      def missing_work_item_parent_links(sub_batch)
        missing_parent_links = EpicIssues
            .select('issues.id as issue_id', 'epics.issue_id as work_item_parent_id, epic_issues.relative_position')
            .joins("JOIN issues ON (issues.id = epic_issues.issue_id)")
            .joins('JOIN epics ON (epic_issues.epic_id = epics.id)')
            .joins("LEFT JOIN work_item_parent_links ON (epic_issues.issue_id = work_item_parent_links.work_item_id)")
            .where(epic_id: sub_batch.select(:id))
            .where(work_item_parent_links: { id: nil })

        missing_parent_links.map do |record|
          {
            work_item_parent_id: record.work_item_parent_id,
            work_item_id: record.issue_id,
            relative_position: record.relative_position
          }
        end
      end

      # WorkItemParentLinks where the the epic is still the correct one, but the work_item_id is still the issue
      # of the old project. Because epic_issues is the SSoT, we expect that these records would have a matching
      # epic_issue record. We need to join issues as only epic <> issue relationships are affected.
      def orphaned_work_item_parent_links(sub_batch)
        WorkItemParentLinks.where(work_item_parent_id: sub_batch.select(:issue_id))
          .joins("LEFT JOIN epic_issues ON (work_item_parent_links.work_item_id = epic_issues.issue_id)")
          .joins('JOIN issues ON (work_item_parent_links.work_item_id = issues.id)')
          .where(epic_issues: { id: nil })
          .where(issues: { work_item_type_id: issue_work_item_type_id })
      end

      def issue_work_item_type_id
        @issue_work_item_type_id ||= WorkItemType.find_by(name: 'Issue').id
      end
    end
  end
end
