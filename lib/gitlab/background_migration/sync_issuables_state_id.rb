# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class SyncIssuablesStateId
      def perform(start_id, end_id, model_class)
        populate_new_state_id(start_id, end_id, model_class)
      end

      def populate_new_state_id(start_id, end_id, model_class)
        Rails.logger.info("#{model_class.model_name.human} - Populating state_id: #{start_id} - #{end_id}")

        ActiveRecord::Base.connection.execute <<~SQL
          UPDATE #{model_class.table_name}
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
