# frozen_string_literal: true

module ActiveContext
  class Migration
    class OperationResult
      attr_reader :operation_name, :completed
      alias_method :completed?, :completed

      def initialize(operation_name)
        @operation_name = operation_name
        @completed = false
      end

      def complete!
        @completed = true
      end
    end
  end
end
