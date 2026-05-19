# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEpicSubscriptionToWorkItems < BatchedMigrationJob
      operation_name :backfill_epic_subscription_to_work_items
      feature_category :portfolio_management
      tables_to_check_for_vacuum :subscriptions

      SUBSCRIPTIONS_BATCH_SIZE = 100

      def perform
        each_sub_batch do |sub_batch|
          delete_duplicate_epic_subscriptions(sub_batch)
          backfill_epic_subscriptions(sub_batch)
        end
      end

      private

      # rubocop: disable Metrics/MethodLength -- this method contains only SQL query
      def delete_duplicate_epic_subscriptions(sub_batch)
        # rubocop:disable Metrics/BlockLength -- this is a SQL query, not Ruby code
        loop do
          result = connection.execute(<<~SQL)
              WITH pairs AS (
                SELECT
                  epic_sub.id                 AS epic_sub_id,
                  work_item_sub.id            AS work_item_sub_id,
                  epic_sub.updated_at         AS epic_updated_at,
                  work_item_sub.updated_at    AS work_item_updated_at
                FROM subscriptions epic_sub
                INNER JOIN epics ON epics.id = epic_sub.subscribable_id
                INNER JOIN subscriptions work_item_sub
                  ON  work_item_sub.subscribable_id   = epics.issue_id
                  AND work_item_sub.subscribable_type = 'Issue'
                  AND work_item_sub.user_id           = epic_sub.user_id
                WHERE epic_sub.subscribable_id IN (#{sub_batch.select(:id).to_sql})
                  AND epic_sub.subscribable_type = 'Epic'
                LIMIT #{SUBSCRIPTIONS_BATCH_SIZE}
            ),
            subscriptions_to_delete AS (
              SELECT
                CASE
                  WHEN epic_updated_at < work_item_updated_at THEN epic_sub_id
                  ELSE work_item_sub_id
                END AS id
              FROM pairs
            )
            DELETE FROM subscriptions
            USING subscriptions_to_delete
            WHERE subscriptions.id = subscriptions_to_delete.id
          SQL

          break if result.cmd_tuples == 0
        end
        # rubocop:enable Metrics/BlockLength
      end
      # rubocop:enable Metrics/MethodLength

      def backfill_epic_subscriptions(sub_batch)
        loop do
          result = connection.execute(<<~SQL)
            WITH subscriptions_for_update AS MATERIALIZED (
              SELECT
                subscriptions.id AS id,
                epics.issue_id AS issue_id
              FROM subscriptions
              INNER JOIN epics ON epics.id = subscriptions.subscribable_id
              WHERE subscriptions.subscribable_id IN (#{sub_batch.select(:id).to_sql})
                AND subscriptions.subscribable_type = 'Epic'
              LIMIT #{SUBSCRIPTIONS_BATCH_SIZE}
            )
            UPDATE subscriptions
            SET subscribable_id = subscriptions_for_update.issue_id,
                subscribable_type = 'Issue'
            FROM subscriptions_for_update
            WHERE subscriptions.id = subscriptions_for_update.id
          SQL

          break if result.cmd_tuples == 0
        end
      end
    end
  end
end
