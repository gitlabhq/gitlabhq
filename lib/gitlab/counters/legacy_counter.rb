# frozen_string_literal: true

module Gitlab
  module Counters
    # This class is a wrapper over ActiveRecord counter
    # for attributes that have not adopted Redis-backed BufferedCounter.
    class LegacyCounter
      def initialize(counter_record, attribute)
        @counter_record = counter_record
        @attribute = attribute
        @current_value = counter_record.method(attribute).call
      end

      def increment(increment)
        updated = update_counter_record_attribute(increment.amount)

        if updated == 1
          counter_record.execute_after_commit_callbacks
          @current_value += increment.amount
        end

        @current_value
      end

      def bulk_increment(increments)
        total_increment = increments.sum(&:amount)

        updated = update_counter_record_attribute(total_increment)

        if updated == 1
          counter_record.execute_after_commit_callbacks
          @current_value += total_increment
        end

        @current_value
      end

      private

      def update_counter_record_attribute(amount)
        counter_record.class.update_counters(counter_record.id, { attribute => amount })
      end

      attr_reader :counter_record, :attribute
    end
  end
end
