# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckOpenStatusService < CheckBaseService
      def execute
        if merge_request.open?
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
        :not_open
      end
    end
  end
end
