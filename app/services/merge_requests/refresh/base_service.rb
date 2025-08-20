# frozen_string_literal: true

module MergeRequests
  module Refresh
    class BaseService < MergeRequests::BaseService
      private

      def merge_requests_for_source_branch(reload: false)
        @source_merge_requests = nil if reload
        @source_merge_requests ||= merge_requests_for(@push.branch_name)
      end
    end
  end
end
