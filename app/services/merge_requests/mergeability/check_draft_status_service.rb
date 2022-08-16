# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckDraftStatusService < CheckBaseService
      def execute
        if merge_request.draft?
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

      private

      def failure_reason
        :draft_status
      end
    end
  end
end
