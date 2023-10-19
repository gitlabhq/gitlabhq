# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckRebaseStatusService < CheckBaseService
      def self.failure_reason
        :need_rebase
      end

      def execute
        if merge_request.should_be_rebased?
          failure(reason: failure_reason)
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
