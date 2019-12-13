# frozen_string_literal: true

module API
  module Helpers
    module ResourceLabelEventsHelpers
      def self.eventable_types
        # This is a method instead of a constant, allowing EE to more easily
        # extend it.
        [Issue, MergeRequest]
      end
    end
  end
end
