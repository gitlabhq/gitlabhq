# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill epic issues into work item parent links
    # There are two ways to use this background migration
    #
    # 1. Backfill every epic_issues record by providing a nil `group_id` argument. batch_table must be
    #    `epic_issues` and batch_column must be `id`.
    # 2. Backfill epic_issues only for a specific group by providing a `group_id` argument. batch_table must be
    #    `epics` and batch_column must be `iid`.
    class BackfillEpicIssuesIntoWorkItemParentLinks < BatchedMigrationJob
      operation_name :backfill_epic_issues_into_work_item_parent_links
      feature_category :team_planning

      job_arguments :group_id
      scope_to ->(relation) { scope_by_arguments(relation) }

      class ParentLink < ApplicationRecord
        self.table_name = :work_item_parent_links
        self.inheritance_column = :_type_disabled
      end

      def perform
        if group_id.present? && (batch_table.to_sym != :epics || batch_column.to_sym != :iid)
          raise 'when group_id is provided, use `epics` as batch_table and `iid` as batch_column'
        end

        if group_id.blank? && batch_table.to_sym == :epics
          raise 'use `epic_issues` as batch_table when no group_id is provided'
        end

        each_sub_batch do |sub_batch|
          ParentLink.transaction do
            if batch_table.to_sym == :epic_issues
              upsert_by_epic_issues(sub_batch)
            else
              upsert_by_epics(sub_batch)
            end
          end
        end
      end

      private

      def scope_by_arguments(relation)
        return relation if group_id.blank?

        relation.where(group_id: group_id)
      end

      def upsert_records(records)
        ParentLink.upsert_all(
          records,
          on_duplicate: :update,
          unique_by: :index_work_item_parent_links_on_work_item_id
        )
      end

      def batch_attributes(sub_batch)
        locked_batch = sub_batch.joins('INNER JOIN epics ON epics.id = epic_issues.epic_id')
                                .select(:id, :epic_id, :issue_id, :relative_position)
                                .select('epics.issue_id AS parent_issue_id')
                                .lock!

        locked_batch.map do |epic_issue|
          {
            work_item_parent_id: epic_issue.parent_issue_id,
            work_item_id: epic_issue.issue_id,
            relative_position: epic_issue.relative_position
          }
        end
      end

      def upsert_by_epics(sub_batch)
        epic_issues.where(epic_id: sub_batch.select(:id)).each_batch(of: 100) do |batch|
          upsert_records(
            batch_attributes(batch)
          )
        end
      end

      def upsert_by_epic_issues(sub_batch)
        upsert_records(
          batch_attributes(sub_batch)
        )
      end

      def epic_issues
        @epic_issues ||= define_batchable_model(:epic_issues, connection: ApplicationRecord.connection)
      end
    end
  end
end
