# frozen_string_literal: true

module API
  module Helpers
    module ResourceEventsHelpers
      def self.eventable_types
        # This is a method instead of a constant, allowing EE to more easily extend it.
        {
          Issue => { feature_category: :team_planning, id_field: 'IID' },
          MergeRequest => { feature_category: :code_review_workflow, id_field: 'IID' }
        }
      end
    end
  end
end

API::Helpers::ResourceEventsHelpers.prepend_mod_with('API::Helpers::ResourceEventsHelpers')
