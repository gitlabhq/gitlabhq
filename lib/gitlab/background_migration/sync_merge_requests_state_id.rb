# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class SyncMergeRequestsStateId
      def perform(start_id, end_id)
        ActiveRecord::Base.connection.execute <<~SQL
          UPDATE merge_requests
          SET state_id =
            CASE state
            WHEN 'opened' THEN 1
            WHEN 'closed' THEN 2
            WHEN 'merged' THEN 3
            WHEN 'locked' THEN 4
            END
          WHERE state_id IS NULL
          AND id BETWEEN #{start_id} AND #{end_id}
        SQL
      end
    end
  end
end
