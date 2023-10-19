# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckDraftStatusService < CheckBaseService
      def self.failure_reason
        :draft_status
      end

      def execute
        if merge_request.draft?
          failure(reason: failure_reason)
        else
          success
        end
      end

      def skip?
        params[:skip_draft_check].present?
      end

      def cacheable?
        false
      end
    end
  end
end
