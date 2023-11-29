# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckConflictStatusService < CheckBaseService
      identifier :conflict
      description 'Checks whether the merge request has a conflict'

      def execute
        if merge_request.can_be_merged?
          success
        else
          failure
        end
      end

      def skip?
        false
      end

      def cacheable?
        false
      end
    end
  end
end
