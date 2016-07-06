module MergeRequests
  module Conflicts
    class FormatterService
      attr_accessor :rugged_input

      def initialize(rugged_input)
        @rugged_input = rugged_input
      end

      def format_from_rugged
        # TODO: format!
        @rugged_input
      end
    end
  end
end
