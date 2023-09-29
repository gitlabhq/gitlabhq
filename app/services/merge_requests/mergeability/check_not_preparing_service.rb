# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckNotPreparingService < CheckBaseService
      def execute
        if !merge_request.preparing?
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
        :preparing
      end
    end
  end
end
