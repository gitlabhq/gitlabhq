# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckCiStatusService < CheckBaseService
      identifier :ci_must_pass
      description 'Checks whether CI has passed'

      def execute
        return inactive unless merge_request.only_allow_merge_if_pipeline_succeeds?

        if merge_request.mergeable_ci_state?
          success
        else
          failure
        end
      end

      def skip?
        params[:skip_ci_check].present?
      end

      def cacheable?
        false
      end
    end
  end
end
