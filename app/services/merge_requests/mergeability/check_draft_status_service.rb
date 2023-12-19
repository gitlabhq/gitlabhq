# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckDraftStatusService < CheckBaseService
      identifier :draft_status
      description 'Checks whether the merge request is draft'

      def execute
        if merge_request.draft?
          failure
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
