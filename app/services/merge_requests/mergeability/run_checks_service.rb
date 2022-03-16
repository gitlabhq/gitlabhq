# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class RunChecksService
      include Gitlab::Utils::StrongMemoize

      # We want to have the cheapest checks first in the list,
      # that way we can fail fast before running the more expensive ones
      CHECKS = [
        CheckOpenStatusService,
        CheckDraftStatusService,
        CheckBrokenStatusService,
        CheckDiscussionsStatusService,
        CheckCiStatusService
      ].freeze

      def initialize(merge_request:, params:)
        @merge_request = merge_request
        @params = params
      end

      def execute
        CHECKS.each_with_object([]) do |check_class, results|
          check = check_class.new(merge_request: merge_request, params: params)

          next if check.skip?

          check_result = run_check(check)
          results << check_result

          break results if check_result.failed?
        end
      end

      private

      attr_reader :merge_request, :params

      def run_check(check)
        return check.execute unless Feature.enabled?(:mergeability_caching, merge_request.project, default_enabled: :yaml)
        return check.execute unless check.cacheable?

        cached_result = results.read(merge_check: check)
        return cached_result if cached_result.respond_to?(:status)

        check.execute.tap do |result|
          results.write(merge_check: check, result_hash: result.to_hash)
        end
      end

      def results
        strong_memoize(:results) do
          Gitlab::MergeRequests::Mergeability::ResultsStore.new(merge_request: merge_request)
        end
      end
    end
  end
end
