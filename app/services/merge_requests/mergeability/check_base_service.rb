# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class CheckBaseService
      attr_reader :merge_request, :params

      def initialize(merge_request:, params:)
        @merge_request = merge_request
        @params = params
      end

      def skip?
        raise NotImplementedError
      end

      # When this method is true, we need to implement a cache_key
      def cacheable?
        raise NotImplementedError
      end

      def cache_key
        raise NotImplementedError
      end

      private

      def success(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult.success(payload: args)
      end

      def failure(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult.failed(payload: args)
      end
    end
  end
end
