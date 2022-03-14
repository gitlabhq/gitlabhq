# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckDraftStatusService < CheckBaseService
      def execute
        if merge_request.draft?
          failure
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
