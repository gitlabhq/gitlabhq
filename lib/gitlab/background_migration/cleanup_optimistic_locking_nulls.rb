# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class CleanupOptimisticLockingNulls
      QUERY_ITEM_SIZE = 1_000

      # table - The name of the table the migration is performed for.
      # start_id - The ID of the object to start at
      # stop_id - The ID of the object to end at
      def perform(start_id, stop_id, table)
        model = define_model_for(table)

        # After analysis done, a batch size of 1,000 items per query was found to be
        # the most optimal. Discussion in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18418#note_282285336
        (start_id..stop_id).each_slice(QUERY_ITEM_SIZE).each do |range|
          model
              .where(lock_version: nil)
              .where("ID BETWEEN ? AND ?", range.first, range.last)
              .update_all(lock_version: 0)
        end
      end

      def define_model_for(table)
        Class.new(ActiveRecord::Base) do
          self.table_name = table
        end
      end
    end
  end
end
