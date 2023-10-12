# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class CheckBrokenStatusService < CheckBaseService
      def self.failure_reason
        :broken_status
      end

      def execute
        if merge_request.broken?
          failure(reason: failure_reason)
        else
          success
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
