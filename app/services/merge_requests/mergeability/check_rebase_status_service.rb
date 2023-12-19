# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckRebaseStatusService < CheckBaseService
      identifier :need_rebase
      description 'Checks whether the merge request needs to be rebased'

      def execute
        return inactive unless merge_request.project.ff_merge_must_be_possible?

        if merge_request.should_be_rebased?
          failure
        else
          success
        end
      end

      def skip?
        params[:skip_rebase_check].present?
      end

      def cacheable?
        false
      end
    end
  end
end
