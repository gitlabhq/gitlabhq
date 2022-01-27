# frozen_string_literal: true

module Gitlab
  module Git
    # ReferenceUpdateError represents an error that happen when trying to
    # update a Git reference.
    class ReferenceUpdateError < StandardError
      def initialize(message, reference, old_oid, new_oid)
        @message = message
        @reference = reference
        @old_oid = old_oid
        @new_oid = new_oid
      end
    end
  end
end
