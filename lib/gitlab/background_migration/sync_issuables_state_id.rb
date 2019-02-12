# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class SyncIssuablesStateId
      def perform(start_id, end_id, table_name)
        populate_new_state_id(start_id, end_id, table_name)
      end

      def populate_new_state_id(start_id, end_id, table_name)
        Rails.logger.info("#{table_name} - Populating state_id: #{start_id} - #{end_id}")

        ActiveRecord::Base.connection.execute <<~SQL
          UPDATE #{table_name}
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
