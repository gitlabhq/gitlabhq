# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Preprocessor
      # A batch can hold 1,000 refs. A log line with the full list can exceed
      # log pipeline limits and get dropped. Log a sample instead.
      LOGGED_REFS_SAMPLE_SIZE = 10

      def preprocessors
        @preprocessors ||= []
      end

      def eligible_preprocessors
        preprocessors.select { |preprocessor| preprocessor[:should_run].call }
      end

      def add_preprocessor(name, should_run: -> { true }, &block)
        preprocessors << { name: name, should_run: should_run, block: block }
      end

      def preprocess(refs, **options)
        result = { successful: [], failed: [], infinite_retry: [] }

        refs_by_class = refs.group_by(&:class)

        refs_by_class.each do |klass, class_refs|
          all_failed_refs = []
          all_infinite_retry_refs = []
          current_successful_refs = class_refs

          klass.eligible_preprocessors.each do |preprocessor|
            next if current_successful_refs.empty?

            processed = preprocessor[:block].call(current_successful_refs, **options)

            all_failed_refs.concat(processed[:failed])
            all_infinite_retry_refs.concat(processed[:infinite_retry] || [])
            current_successful_refs = processed[:successful]
          end

          result[:successful].concat(current_successful_refs)
          result[:failed].concat(all_failed_refs)
          result[:infinite_retry].concat(all_infinite_retry_refs)
        end

        result
      end

      def with_per_ref_handling(
        refs,
        retry_error_types: [StandardError],
        skip_error_types: [],
        queue_name: nil,
        preprocessor: nil)
        return { successful: [], failed: [] } unless refs.any?

        failed_refs = []
        successful_refs = []

        refs.each do |ref|
          yield(ref)
          successful_refs << ref
        rescue *skip_error_types => e
          ::ActiveContext::Logger.exception(
            e,
            handling: :skipped,
            class_name: name,
            queue_name: queue_name,
            preprocessor: preprocessor,
            reference: ref.serialize,
            reference_id: ref.identifier
          )
        rescue *retry_error_types => e
          ::ActiveContext::Logger.exception(
            e,
            handling: :retryable,
            class_name: name,
            queue_name: queue_name,
            preprocessor: preprocessor,
            reference: ref.serialize,
            reference_id: ref.identifier
          )

          failed_refs << ref
        end

        { successful: successful_refs, failed: failed_refs }
      end

      def with_batch_handling(
        refs,
        error_types: [StandardError],
        infinite_retry_error_types: [],
        queue_name: nil,
        preprocessor: nil)
        return { successful: [], failed: [], infinite_retry: [] } unless refs.any?

        begin
          yield(refs)

          { successful: refs, failed: [], infinite_retry: [] }
        rescue *infinite_retry_error_types => e
          log_batch_failure(e, refs, handling: :infinite_retry, queue_name: queue_name, preprocessor: preprocessor)

          { successful: [], failed: [], infinite_retry: refs }
        rescue *error_types => e
          log_batch_failure(e, refs, handling: :retryable, queue_name: queue_name, preprocessor: preprocessor)

          { successful: [], failed: refs, infinite_retry: [] }
        rescue StandardError => e
          # This error is not in the caller's `error_types` list.
          # Log it as an error, not a warning, so it does not hide with expected failures.
          log_batch_failure(e, refs, handling: :unexpected, queue_name: queue_name, preprocessor: preprocessor)

          { successful: [], failed: refs, infinite_retry: [] }
        end
      end

      private

      def log_batch_failure(exception, refs, handling:, queue_name:, preprocessor:)
        ::ActiveContext::Logger.exception(
          exception,
          handling: handling,
          class_name: name,
          queue_name: queue_name,
          preprocessor: preprocessor,
          refs_count: refs.count,
          refs_sample: refs.first(LOGGED_REFS_SAMPLE_SIZE).map(&:serialize)
        )
      end

      def grouped_processing_result(grouped_refs)
        initial_result = { successful: [], failed: [], infinite_retry: [] }
        grouped_refs.each_with_object(initial_result) do |(group_key, refs_in_group), result|
          group_result = yield(group_key, refs_in_group)

          result[:successful] += group_result[:successful]
          result[:failed] += group_result[:failed]
          result[:infinite_retry] += group_result[:infinite_retry].to_a
        end
      end
    end
  end
end
