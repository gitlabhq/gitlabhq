# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDescriptionVersionsForEpics < BatchedMigrationJob
      cursor :id

      operation_name :backfill_description_versions_for_epics
      feature_category :portfolio_management

      def perform
        each_sub_batch do |sub_batch|
          backfill_issue_id(sub_batch)
        end
      end

      private

      def backfill_issue_id(sub_batch)
        epic_ids_sql = sub_batch.select(:id).reorder(nil).to_sql
        min_id, max_id = sub_batch.reorder(nil).pick(Arel.sql('MIN(id), MAX(id)'))

        connection.execute(<<~SQL)
          UPDATE description_versions
          SET issue_id = epics.issue_id,
              epic_id = NULL
          FROM epics
          WHERE epics.id = description_versions.epic_id
            AND epics.id IN (#{epic_ids_sql})
            AND description_versions.epic_id >= #{min_id}
            AND description_versions.epic_id <= #{max_id}
        SQL
      end
    end
  end
end
