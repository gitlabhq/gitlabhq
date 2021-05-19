# frozen_string_literal: true

module API
  module Helpers
    module DiscussionsHelpers
      def self.feature_category_per_noteable_type
        # This is a method instead of a constant, allowing EE to more easily
        # extend it.
        {
          Issue => :issue_tracking,
          Snippet => :snippets,
          MergeRequest => :code_review,
          Commit => :code_review
        }
      end
    end
  end
end

API::Helpers::DiscussionsHelpers.prepend_mod_with('API::Helpers::DiscussionsHelpers')
