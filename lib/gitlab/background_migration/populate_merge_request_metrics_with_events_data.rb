# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ClassLength
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateMergeRequestMetricsWithEventsData
      def perform(min_merge_request_id, max_merge_request_id)
        insert_metrics_for_range(min_merge_request_id, max_merge_request_id)
        update_metrics_with_events_data(min_merge_request_id, max_merge_request_id)
      end

      # Inserts merge_request_metrics records for merge_requests without it for
      # a given merge request batch.
      def insert_metrics_for_range(min, max)
        metrics_not_exists_clause =
          <<-SQL.strip_heredoc
            NOT EXISTS (SELECT 1 FROM merge_request_metrics
                        WHERE merge_request_metrics.merge_request_id = merge_requests.id)
          SQL

        MergeRequest.where(metrics_not_exists_clause).where(id: min..max).each_batch do |batch|
          select_sql = batch.select(:id, :created_at, :updated_at).to_sql

          execute("INSERT INTO merge_request_metrics (merge_request_id, created_at, updated_at) #{select_sql}")
        end
      end

      def update_metrics_with_events_data(min, max)
        if Gitlab::Database.postgresql?
          # Uses WITH syntax in order to update merged and closed events with a single UPDATE.
          # WITH is not supported by MySQL.
          update_events_for_range(min, max)
        else
          update_merged_events_for_range(min, max)
          update_closed_events_for_range(min, max)
        end
      end

      private

      # Updates merge_request_metrics latest_closed_at, latest_closed_by_id and merged_by_id
      # based on the latest event records on events table for a given merge request batch.
      def update_events_for_range(min, max)
        sql = <<-SQL.strip_heredoc
          WITH events_for_update AS (
            SELECT DISTINCT ON (target_id, action) target_id, action, author_id, updated_at
             FROM events
            WHERE target_id BETWEEN #{min} AND #{max}
              AND target_type = 'MergeRequest'
              AND action IN (#{Event::CLOSED},#{Event::MERGED})
            ORDER BY target_id, action, id DESC
          )
          UPDATE merge_request_metrics met
            SET latest_closed_at = latest_closed.updated_at,
                latest_closed_by_id = latest_closed.author_id,
                merged_by_id = latest_merged.author_id
           FROM (SELECT * FROM events_for_update WHERE action = #{Event::CLOSED}) AS latest_closed
           FULL OUTER JOIN
                (SELECT * FROM events_for_update WHERE action = #{Event::MERGED}) AS latest_merged
          USING (target_id)
          WHERE target_id = merge_request_id;
        SQL

        execute(sql)
      end

      # Updates merge_request_metrics latest_closed_at, latest_closed_by_id based on the latest closed
      # records on events table for a given merge request batch.
      def update_closed_events_for_range(min, max)
        sql =
          <<-SQL.strip_heredoc
            UPDATE merge_request_metrics metrics,
              (#{select_events(min, max, Event::CLOSED)}) closed_events
            SET metrics.latest_closed_by_id = closed_events.author_id,
                metrics.latest_closed_at = closed_events.updated_at #{where_matches_closed_events};
          SQL

        execute(sql)
      end

      # Updates merge_request_metrics merged_by_id based on the latest merged
      # records on events table for a given merge request batch.
      def update_merged_events_for_range(min, max)
        sql =
          <<-SQL.strip_heredoc
            UPDATE merge_request_metrics metrics,
              (#{select_events(min, max, Event::MERGED)}) merged_events
            SET metrics.merged_by_id = merged_events.author_id #{where_matches_merged_events};
          SQL

        execute(sql)
      end

      def execute(sql)
        @connection ||= ActiveRecord::Base.connection
        @connection.execute(sql)
      end

      def select_events(min, max, action)
        select_max_event_id = <<-SQL.strip_heredoc
          SELECT max(id)
          FROM events
          WHERE action = #{action}
          AND target_type = 'MergeRequest'
          AND target_id BETWEEN #{min} AND #{max}
          GROUP BY target_id
        SQL

        <<-SQL.strip_heredoc
          SELECT author_id, updated_at, target_id
          FROM events
          WHERE id IN(#{select_max_event_id})
        SQL
      end

      def where_matches_closed_events
        <<-SQL.strip_heredoc
          WHERE metrics.merge_request_id = closed_events.target_id
          AND metrics.latest_closed_at IS NULL
          AND metrics.latest_closed_by_id IS NULL
        SQL
      end

      def where_matches_merged_events
        <<-SQL.strip_heredoc
          WHERE metrics.merge_request_id = merged_events.target_id
          AND metrics.merged_by_id IS NULL
        SQL
      end
    end
  end
end
