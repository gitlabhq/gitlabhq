# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class RunChecksService
      include Gitlab::Utils::StrongMemoize

      def initialize(merge_request:, params:)
        @merge_request = merge_request
        @params = params
      end

      def execute
        @results = merge_request.mergeability_checks.each_with_object([]) do |check_class, result_hash|
          check = check_class.new(merge_request: merge_request, params: params)

          next if check.skip?

          check_result = logger.instrument(mergeability_name: check_class.to_s.demodulize.underscore) do
            run_check(check)
          end

          result_hash << check_result

          break result_hash if check_result.failed?
        end

        logger.commit

        self
      end

      def success?
        raise 'Execute needs to be called before' if results.nil?

        results.all?(&:success?)
      end

      def failure_reason
        raise 'Execute needs to be called before' if results.nil?

        results.find(&:failed?)&.payload&.fetch(:reason)&.to_sym
      end

      private

      attr_reader :merge_request, :params, :results

      def run_check(check)
        return check.execute unless check.cacheable?

        cached_result = cached_results.read(merge_check: check)
        return cached_result if cached_result.respond_to?(:status)

        check.execute.tap do |result|
          cached_results.write(merge_check: check, result_hash: result.to_hash)
        end
      end

      def cached_results
        strong_memoize(:cached_results) do
          Gitlab::MergeRequests::Mergeability::ResultsStore.new(merge_request: merge_request)
        end
      end

      def logger
        strong_memoize(:logger) do
          MergeRequests::Mergeability::Logger.new(merge_request: merge_request)
        end
      end
    end
  end
end
