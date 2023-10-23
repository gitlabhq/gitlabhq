# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class CheckBaseService
      attr_reader :merge_request, :params

      def initialize(merge_request:, params:)
        @merge_request = merge_request
        @params = params
      end

      def self.identifier
        failure_reason
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

      def failure_reason
        self.class.failure_reason
      end

      def success(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult
          .success(payload: default_payload(args))
      end

      def failure(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult
          .failed(payload: default_payload(args))
      end

      def inactive(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult
          .inactive(payload: default_payload(args))
      end

      def default_payload(args)
        args.merge(identifier: self.class.identifier)
      end
    end
  end
end
