# frozen_string_literal: true

module API
  module Helpers
    module DiscussionsHelpers
      def self.noteable_types
        # This is a method instead of a constant, allowing EE to more easily
        # extend it.
        [Issue, Snippet, MergeRequest, Commit]
      end
    end
  end
end
