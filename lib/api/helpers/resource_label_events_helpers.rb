# frozen_string_literal: true

module API
  module Helpers
    module ResourceLabelEventsHelpers
      def self.feature_category_per_eventable_type
        # This is a method instead of a constant, allowing EE to more easily
        # extend it.
        {
          Issue => :issue_tracking,
          MergeRequest => :code_review
        }
      end
    end
  end
end

API::Helpers::ResourceLabelEventsHelpers.prepend_mod_with('API::Helpers::ResourceLabelEventsHelpers')
