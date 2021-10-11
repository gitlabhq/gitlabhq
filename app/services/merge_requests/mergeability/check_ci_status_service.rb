# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class CheckCiStatusService < CheckBaseService
      def execute
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
