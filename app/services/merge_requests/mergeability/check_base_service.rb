# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class CheckBaseService
      attr_reader :merge_request, :params

      class_attribute :identifier, :description

      def self.identifier(new_identifier)
        self.identifier = new_identifier
      end

      def self.description(new_description)
        self.description = new_description
      end

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
        Gitlab::MergeRequests::Mergeability::CheckResult
          .success(payload: default_payload(args))
      end

      def checking(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult
          .checking(payload: default_payload(args))
      end

      def failure(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult
          .failed(payload: default_payload(args))
      end

      def inactive(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult
          .inactive(payload: default_payload(args))
      end

      def warning(**args)
        Gitlab::MergeRequests::Mergeability::CheckResult
          .warning(payload: default_payload(args))
      end

      def default_payload(args)
        args.merge(identifier: self.class.identifier)
      end
    end
  end
end
