# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration creates records on merge_request_assignees according
    # to the given merge request IDs range. A _single_ INSERT is issued for the given range.
    # This is required for supporting multiple assignees on merge requests.
    class PopulateMergeRequestAssigneesTable
      def perform(from_id, to_id)
        select_sql =
          MergeRequest
            .where(merge_request_assignees_not_exists_clause)
            .where(id: from_id..to_id)
            .where.not(assignee_id: nil)
            .select(:id, :assignee_id)
            .to_sql

        execute("INSERT INTO merge_request_assignees (merge_request_id, user_id) #{select_sql}")
      end

      def perform_all_sync(batch_size:)
        MergeRequest.each_batch(of: batch_size) do |batch|
          range = batch.pluck('MIN(id)', 'MAX(id)').first

          perform(*range)
        end
      end

      private

      def merge_request_assignees_not_exists_clause
        <<~SQL
            NOT EXISTS (SELECT 1 FROM merge_request_assignees
                        WHERE merge_request_assignees.merge_request_id = merge_requests.id)
        SQL
      end

      def execute(sql)
        @connection ||= ActiveRecord::Base.connection
        @connection.execute(sql)
      end
    end
  end
end
