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

API::Helpers::ResourceLabelEventsHelpers.prepend_if_ee('EE::API::Helpers::ResourceLabelEventsHelpers')
