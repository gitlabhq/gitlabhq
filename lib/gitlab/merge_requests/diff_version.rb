# frozen_string_literal: true

module Gitlab
  module MergeRequests
    class DiffVersion
      def initialize(merge_request, params = {})
        @merge_request = merge_request
        @params = params
      end

      def resolve
        return merge_request.merge_head_diff if merge_request.diffable_merge_ref?

        merge_request.merge_request_diff
      end

      private

      attr_reader :merge_request, :params
    end
  end
end
