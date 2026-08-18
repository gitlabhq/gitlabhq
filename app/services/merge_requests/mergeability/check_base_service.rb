# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckBaseService
      attr_reader :merge_request, :params

      class_attribute :identifier, :description, :failure_explanation

      def self.set_identifier(value)
        self.identifier = value
      end

      def self.set_description(value)
        self.description = value
      end

      # User-facing explanation shown when this check fails, for example in the
      # merge-train "Merge request is not mergeable" error. Marked with N_ for
      # extraction, but note there is no display-time translation for these
      # today: they are only baked into persisted, English-only system notes
      # and merge_error, so they render in English regardless of locale.
      def self.set_failure_explanation(value)
        self.failure_explanation = value
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

      def cache_ttl
        6.hours
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
        args.merge(
          identifier: self.class.identifier,
          failure_explanation: self.class.failure_explanation
        )
      end
    end
  end
end
