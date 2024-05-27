# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillRelatedEpicLinksToIssueLinks < BatchedMigrationJob
      operation_name :backfill_issue_links_with_related_epic_links
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          values_subquery = sub_batch.select(select_fields_to_insert_sql)
          values_subquery = values_subquery.joins(joins_target_and_source_epic_sql)

          connection.execute(<<~SQL)
            INSERT INTO issue_links (source_id, target_id, link_type, created_at, updated_at)
             #{values_subquery.to_sql}
            ON CONFLICT (source_id, target_id)
            DO UPDATE SET
              link_type = EXCLUDED.link_type,
              created_at = EXCLUDED.created_at,
              updated_at = EXCLUDED.updated_at
          SQL
        end
      end

      private

      def select_fields_to_insert_sql
        <<~SQL
          source_epics.issue_id AS source_id,
          target_epics.issue_id AS target_id,
          related_epic_links.link_type,
          related_epic_links.created_at AT TIME ZONE '#{Time.zone.tzinfo.name}' AS created_at,
          related_epic_links.updated_at AT TIME ZONE '#{Time.zone.tzinfo.name}' AS updated_at
        SQL
      end

      def joins_target_and_source_epic_sql
        <<~SQL
          INNER JOIN epics source_epics ON related_epic_links.source_id = source_epics.id
          INNER JOIN epics target_epics ON related_epic_links.target_id = target_epics.id
        SQL
      end
    end
  end
end
