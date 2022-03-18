# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class CheckDiscussionsStatusService < CheckBaseService
      def execute
        if merge_request.mergeable_discussions_state?
          success
        else
          failure
        end
      end

      def skip?
        params[:skip_discussions_check].present?
      end

      def cacheable?
        false
      end
    end
  end
end
