# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # == Reschedulable helper
    #
    # Allows background migrations to be rescheduled if a condition is met,
    # the condition should be overridden in classes in #should_reschedule? method.
    #
    # For example, check DeleteDiffFiles migration which is rescheduled if dead tuple count
    # on DB is not acceptable.
    #
    module Reschedulable
      extend ActiveSupport::Concern

      # Use this method to perform the background migration and it will be rescheduled
      # if #should_reschedule? returns true.
      def reschedule_if_needed(*args, &block)
        if should_reschedule?
          BackgroundMigrationWorker.perform_in(wait_time, self.class.name.demodulize, args)
        else
          yield
        end
      end

      # Override this on base class if you need a different reschedule condition
      def should_reschedule?
        raise NotImplementedError, "#{self.class} does not implement #{__method__}"
      end

      # Override in subclass if a different dead tuple threshold
      def dead_tuples_threshold
        @dead_tuples_threshold ||= 50_000
      end

      # Override in subclass if a different wait time
      def wait_time
        @wait_time ||= 5.minutes
      end

      def execute_statement(sql)
        ActiveRecord::Base.connection.execute(sql)
      end

      def wait_for_deadtuple_vacuum?(table_name)
        return false unless Gitlab::Database.postgresql?

        dead_tuples_count_for(table_name) >= dead_tuples_threshold
      end

      def dead_tuples_count_for(table_name)
        dead_tuple =
          execute_statement("SELECT n_dead_tup FROM pg_stat_all_tables "\
                            "WHERE relname = '#{table_name}'")[0]

        dead_tuple&.fetch('n_dead_tup', 0).to_i
      end
    end
  end
end
