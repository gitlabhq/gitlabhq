# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class SyncIssuesStateId
      def perform(start_id, end_id)
        ActiveRecord::Base.connection.execute <<~SQL
          UPDATE issues
          SET state_id =
            CASE state
            WHEN 'opened' THEN 1
            WHEN 'closed' THEN 2
            END
          WHERE state_id IS NULL
          AND id BETWEEN #{start_id} AND #{end_id}
        SQL
      end
    end
  end
end
