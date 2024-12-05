# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueLinkIdOnRelatedEpicLinks < BatchedMigrationJob
      operation_name :backfill_issue_links_on_related_epic_links
      feature_category :team_planning

      class RelatedEpicLink < ApplicationRecord
        self.table_name = 'related_epic_links'
      end

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
            UPDATE related_epic_links
            SET issue_link_id = issue_links.id
            FROM issue_links
              JOIN epics source_epics ON source_epics.issue_id = issue_links.source_id
              JOIN epics target_epics ON target_epics.issue_id = issue_links.target_id
            WHERE
              related_epic_links.source_id = source_epics.id
              AND related_epic_links.target_id = target_epics.id
              AND related_epic_links.id IN (#{sub_batch.select(:id).to_sql})
            SQL
          )
        end
      end
    end
  end
end
