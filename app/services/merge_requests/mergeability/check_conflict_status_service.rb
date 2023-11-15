# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckConflictStatusService < CheckBaseService
      def self.failure_reason
        :conflict
      end

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
