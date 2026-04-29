# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckApprovedStatusService < CheckBaseService
      set_identifier :not_approved
      set_description 'Checks whether the merge request has the required approvals'

      def execute
        return inactive unless merge_request.requires_approvals?

        if merge_request.approvals_given >= merge_request.approvals_required
          success
        else
          failure
        end
      end

      def skip?
        params[:skip_approved_check].present?
      end

      def cacheable?
        false
      end
    end
  end
end
