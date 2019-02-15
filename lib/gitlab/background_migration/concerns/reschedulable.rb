# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module Reschedulable
      extend ActiveSupport::Concern

      def reschedule_if_needed(args, &block)
        if should_reschedule?
          BackgroundMigrationWorker.perform_in(vacuum_wait_time, self.class.name.demodulize, args)
        else
          yield
        end
      end

      # Override this on base class if you need a different reschedule condition
      def should_reschedule?
        raise NotImplementedError, "#{self.class} does not implement #{__method__}"
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

      def execute_statement(sql)
        ActiveRecord::Base.connection.execute(sql)
      end

      # Override in subclass if you need a different dead tuple threshold
      def dead_tuples_threshold
        @dead_tuples_threshold ||= 50_000
      end

      # Override in subclass if you need a different vacuum wait time
      def vacuum_wait_time
        @vacuum_wait_time ||= 5.minutes
      end
    end
  end
end
