# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateMergeRequestMetricsWithEventsDataImproved
      CLOSED_EVENT_ACTION = 3
      MERGED_EVENT_ACTION = 7

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
          psql_update_metrics_with_events_data(min, max)
        else
          mysql_update_metrics_with_events_data(min, max)
        end
      end

      def psql_update_metrics_with_events_data(min, max)
        update_sql = <<-SQL.strip_heredoc
          UPDATE merge_request_metrics
          SET (latest_closed_at,
             latest_closed_by_id) =
          ( SELECT updated_at,
                   author_id
           FROM events
           WHERE target_id = merge_request_id
             AND target_type = 'MergeRequest'
             AND action = #{CLOSED_EVENT_ACTION}
           ORDER BY id DESC
           LIMIT 1 ),
             merged_by_id =
          ( SELECT author_id
           FROM events
           WHERE target_id = merge_request_id
             AND target_type = 'MergeRequest'
             AND action = #{MERGED_EVENT_ACTION}
           ORDER BY id DESC
           LIMIT 1 )
          WHERE merge_request_id BETWEEN #{min} AND #{max}
        SQL

        execute(update_sql)
      end

      def mysql_update_metrics_with_events_data(min, max)
        closed_updated_at_subquery = mysql_events_select(:updated_at, CLOSED_EVENT_ACTION)
        closed_author_id_subquery = mysql_events_select(:author_id, CLOSED_EVENT_ACTION)
        merged_author_id_subquery = mysql_events_select(:author_id, MERGED_EVENT_ACTION)

        update_sql = <<-SQL.strip_heredoc
          UPDATE merge_request_metrics
          SET latest_closed_at = (#{closed_updated_at_subquery}),
              latest_closed_by_id = (#{closed_author_id_subquery}),
              merged_by_id = (#{merged_author_id_subquery})
          WHERE merge_request_id BETWEEN #{min} AND #{max}
        SQL

        execute(update_sql)
      end

      def mysql_events_select(column, action)
        <<-SQL.strip_heredoc
          SELECT #{column} FROM events
           WHERE target_id = merge_request_id
             AND target_type = 'MergeRequest'
             AND action = #{action}
           ORDER BY id DESC
           LIMIT 1
        SQL
      end

      def execute(sql)
        @connection ||= ActiveRecord::Base.connection
        @connection.execute(sql)
      end
    end
  end
end
