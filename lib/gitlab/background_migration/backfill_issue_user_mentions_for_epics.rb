# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueUserMentionsForEpics < BatchedMigrationJob
      feature_category :portfolio_management
      operation_name :backfill_issue_user_mentions_for_epics

      def perform
        each_sub_batch do |sub_batch|
          connection.transaction do
            backfill_description_mentions(sub_batch)
            backfill_note_mentions(sub_batch)
          end
        end
      end

      private

      def backfill_description_mentions(sub_batch)
        connection.execute(<<~SQL)
          INSERT INTO issue_user_mentions (issue_id, namespace_id, mentioned_users_ids, mentioned_projects_ids, mentioned_groups_ids, note_id)
          SELECT
            epics.issue_id,
            issues.namespace_id,
            epic_user_mentions.mentioned_users_ids,
            epic_user_mentions.mentioned_projects_ids,
            epic_user_mentions.mentioned_groups_ids,
            epic_user_mentions.note_id
          FROM (#{sub_batch.select(:id, :epic_id, :mentioned_users_ids, :mentioned_projects_ids, :mentioned_groups_ids, :note_id).to_sql}) AS epic_user_mentions
          INNER JOIN epics ON epic_user_mentions.epic_id = epics.id
          INNER JOIN issues ON epics.issue_id = issues.id
          WHERE epic_user_mentions.note_id IS NULL
          ON CONFLICT (issue_id) WHERE note_id IS NULL DO NOTHING
        SQL
      end

      def backfill_note_mentions(sub_batch)
        connection.execute(<<~SQL)
          INSERT INTO issue_user_mentions (issue_id, namespace_id, mentioned_users_ids, mentioned_projects_ids, mentioned_groups_ids, note_id)
          SELECT
            epics.issue_id,
            issues.namespace_id,
            epic_user_mentions.mentioned_users_ids,
            epic_user_mentions.mentioned_projects_ids,
            epic_user_mentions.mentioned_groups_ids,
            epic_user_mentions.note_id
          FROM (#{sub_batch.select(:id, :epic_id, :mentioned_users_ids, :mentioned_projects_ids, :mentioned_groups_ids, :note_id).to_sql}) AS epic_user_mentions
          INNER JOIN epics ON epic_user_mentions.epic_id = epics.id
          INNER JOIN issues ON epics.issue_id = issues.id
          WHERE epic_user_mentions.note_id IS NOT NULL
          ON CONFLICT (issue_id, note_id) DO NOTHING
        SQL
      end
    end
  end
end
