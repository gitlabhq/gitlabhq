# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class to populate project_id for timelogs
    class UpdateTimelogsProjectId
      BATCH_SIZE = 1000

      def perform(start_id, stop_id)
        (start_id..stop_id).step(BATCH_SIZE).each do |offset|
          update_issue_timelogs(offset, offset + BATCH_SIZE)
          update_merge_request_timelogs(offset, offset + BATCH_SIZE)
        end
      end

      def update_issue_timelogs(batch_start, batch_stop)
        execute(<<~SQL)
          UPDATE timelogs
          SET project_id = issues.project_id
          FROM issues
          WHERE issues.id = timelogs.issue_id
          AND timelogs.id BETWEEN #{batch_start} AND #{batch_stop}
          AND timelogs.project_id IS NULL;
        SQL
      end

      def update_merge_request_timelogs(batch_start, batch_stop)
        execute(<<~SQL)
          UPDATE timelogs
          SET project_id = merge_requests.target_project_id
          FROM merge_requests
          WHERE merge_requests.id = timelogs.merge_request_id
          AND timelogs.id BETWEEN #{batch_start} AND #{batch_stop}
          AND timelogs.project_id IS NULL;
        SQL
      end

      def execute(sql)
        @connection ||= ::ActiveRecord::Base.connection
        @connection.execute(sql)
      end
    end
  end
end
