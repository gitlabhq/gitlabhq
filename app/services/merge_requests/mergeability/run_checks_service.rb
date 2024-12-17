# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class RunChecksService
      include Gitlab::Utils::StrongMemoize

      def initialize(merge_request:, params:)
        @merge_request = merge_request
        @params = params
      end

      def execute(checks, execute_all: false)
        @results = checks.each_with_object([]) do |check_class, result_hash|
          check = check_class.new(merge_request: merge_request, params: params)

          next if check.skip?

          check_result = logger.instrument(mergeability_name: check_class.to_s.demodulize.underscore) do
            run_check(check)
          end

          result_hash << check_result

          break result_hash if check_result.unsuccessful? && !execute_all
        end

        logger.commit

        return ServiceResponse.success(payload: { results: results }) if no_result_unsuccessful?

        ServiceResponse.error(
          message: 'Checks were not successful',
          payload: {
            results: results,
            unsuccessful_check: unsuccessful_check
          }
        )
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
        Gitlab::MergeRequests::Mergeability::ResultsStore.new(merge_request: merge_request)
      end
      strong_memoize_attr :cached_results

      def logger
        MergeRequests::Mergeability::Logger.new(merge_request: merge_request)
      end
      strong_memoize_attr :logger

      # This name may seem like a double-negative, but it is meaningful because
      # #success? is _not_ the inverse of #unsuccessful?
      def no_result_unsuccessful?
        results.none?(&:unsuccessful?)
      end

      def unsuccessful_check
        # NOTE: the identifier could be string when we retrieve it from the cache
        # so let's make sure we always return symbols here.
        results.find(&:unsuccessful?)&.payload&.fetch(:identifier)&.to_sym
      end
    end
  end
end
