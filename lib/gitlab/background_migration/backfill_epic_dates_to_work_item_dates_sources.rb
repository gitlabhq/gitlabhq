# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEpicDatesToWorkItemDatesSources < BatchedMigrationJob
      operation_name :backfill_work_item_dates_sources_with_epic_dates
      feature_category :team_planning

      class Epics < ApplicationRecord
        self.table_name = 'epics'
        self.inheritance_column = :_type_disabled
      end

      class WorkItemDatesSources < ApplicationRecord
        self.table_name = 'work_item_dates_sources'
        self.inheritance_column = :_type_disabled
      end

      def perform
        each_sub_batch do |sub_batch|
          backfill_epics_dates(sub_batch.all)
        end
      end

      private

      def backfill_epics_dates(sub_batch)
        Epics.transaction do
          # prevent an epic being updated while we sync its data to work_item_dates_sources table.
          date_sources = build_work_items_dates_source(sub_batch.lock!('FOR UPDATE').load)

          WorkItemDatesSources.upsert_all(date_sources, unique_by: :issue_id) unless date_sources.blank?
        end
      end

      def build_work_items_dates_source(epics_batch)
        source_epics = Epics
                     .where(id: epics_batch.pluck(:start_date_sourcing_epic_id, :due_date_sourcing_epic_id).flatten)
                     .select(:id, :issue_id)
                     .index_by(&:id)

        epics_batch.map do |epic|
          {
            issue_id: epic.issue_id,
            namespace_id: epic.group_id,
            start_date_is_fixed: epic.start_date_is_fixed.present?,
            due_date_is_fixed: epic.due_date_is_fixed.present?,
            start_date: epic.start_date,
            due_date: epic.end_date,
            start_date_sourcing_work_item_id: source_epics[epic.start_date_sourcing_epic_id]&.issue_id,
            start_date_sourcing_milestone_id: epic.start_date_sourcing_milestone_id,
            due_date_sourcing_work_item_id: source_epics[epic.due_date_sourcing_epic_id]&.issue_id,
            due_date_sourcing_milestone_id: epic.due_date_sourcing_milestone_id,
            start_date_fixed: epic.start_date_fixed,
            due_date_fixed: epic.due_date_fixed
          }
        end
      end
    end
  end
end
