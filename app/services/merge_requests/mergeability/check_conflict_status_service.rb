# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckConflictStatusService < CheckBaseService
      def execute
        if merge_request.can_be_merged?
          success
        else
          failure(reason: failure_reason)
        end
      end

      def skip?
        false
      end

      def cacheable?
        false
      end

      private

      def failure_reason
        :conflict
      end
    end
  end
end
