# frozen_string_literal: true

module BulkImports
  module Pipeline
    module Runner
      extend ActiveSupport::Concern

      MarkedAsFailedError = Class.new(StandardError)

      def run
        raise MarkedAsFailedError if context.entity.failed?

        info(message: 'Pipeline started')

        set_source_objects_counter
        extracted_data = extracted_data_from

        if extracted_data
          extracted_data.each_with_index do |entry, index|
            refresh_entity_and_import if index % 1000 == 0

            raw_entry = entry.dup
            next if already_processed?(raw_entry, index)

            delete_partial_imported_records(entry)

            increment_fetched_objects_counter

            transformers.each do |transformer|
              entry = run_pipeline_step(:transformer, transformer.class.name) do
                transformer.transform(context, entry)
              end
            end

            run_pipeline_step(:loader, loader.class.name, entry) do
              loader.load(context, entry)

              increment_imported_objects_counter
            end

            save_processed_entry(raw_entry, index)
          end

          tracker.update!(
            has_next_page: extracted_data.has_next_page?,
            next_page: extracted_data.next_page
          )

          run_pipeline_step(:after_run) do
            after_run(extracted_data)
          end

          # For batches, `#on_finish` is called once within `FinishBatchedPipelineWorker`
          # after all batches have completed.
          unless tracker.batched?
            run_pipeline_step(:on_finish) do
              on_finish
            end
          end
        end

        info(message: 'Pipeline finished')
      rescue MarkedAsFailedError
        skip!('Skipping pipeline due to failed entity')
      end

      def on_finish; end

      private

      def run_pipeline_step(step, class_name = nil, entry = nil)
        raise MarkedAsFailedError if context.entity.failed?

        info(pipeline_step: step, step_class: class_name)

        yield
      rescue MarkedAsFailedError
        skip!(
          'Skipping pipeline due to failed entity',
          pipeline_step: step,
          step_class: class_name,
          importer: 'gitlab_migration'
        )
      rescue BulkImports::NetworkError => e
        raise BulkImports::RetryPipelineError.new(e.message, e.retry_delay), cause: e if e.retriable?(context.tracker)

        log_and_fail(e, step, entry)
      rescue Gitlab::Import::SourceUserMapper::FailedToObtainLockError,
        Gitlab::Import::SourceUserMapper::DuplicatedUserError => e

        raise BulkImports::RetryPipelineError.new(e.message), cause: e
      rescue BulkImports::RetryPipelineError
        raise
      rescue StandardError => e
        log_and_fail(e, step, entry)
      end

      def extracted_data_from
        run_pipeline_step(:extractor, extractor.class.name) do
          extractor.extract(context)
        end
      end

      def cache_key
        batch_number = context.extra[:batch_number] || 0

        "#{self.class.name.underscore}/#{tracker.bulk_import_entity_id}/#{batch_number}"
      end

      # Overridden by child pipelines with different caching strategies
      def already_processed?(*)
        false
      end

      def save_processed_entry(*); end

      # Overridden by child pipelines
      # This method is called once for the first non-processed item returned in the extract step,
      # meaning that, in the case of a pipeline retrial, it is called again for the latest partially
      # processed item.
      def delete_existing_records(*); end

      def delete_partial_imported_records(entry)
        # Using memoization to execute delete_existing_records method only once
        @clean_up_upon_retry ||= begin
          delete_existing_records(entry)

          true
        end
      end

      def after_run(extracted_data)
        run if extracted_data.has_next_page?
      end

      def log_and_fail(exception, step, entry = nil)
        log_import_failure(exception, step, entry)

        if abort_on_failure?
          tracker.fail_op!

          warn(message: 'Aborting entity migration due to pipeline failure')
          context.entity.fail_op!
        end

        nil
      end

      def skip!(message, extra = {})
        warn({ message: message }.merge(extra))

        tracker.skip!
      end

      def log_import_failure(exception, step, entry)
        failure_attributes = {
          bulk_import_entity_id: context.entity.id,
          pipeline_class: pipeline,
          pipeline_step: step,
          exception_class: exception.class.to_s,
          exception_message: exception.message,
          correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
        }

        if entry
          failure_attributes[:source_url] = BulkImports::SourceUrlBuilder.new(context, entry).url
          failure_attributes[:source_title] = entry.try(:title) || entry.try(:name)
        end

        log_exception(
          exception,
          log_params(
            {
              bulk_import_id: context.bulk_import_id,
              pipeline_step: step,
              message: 'An object of a pipeline failed to import'
            }
          )
        )

        BulkImports::Failure.create(failure_attributes)
      end

      def info(extra = {})
        logger.info(log_params(extra))
      end

      def warn(extra = {})
        logger.warn(log_params(extra))
      end

      def log_params(extra)
        defaults = {
          bulk_import_id: context.bulk_import_id,
          pipeline_class: pipeline,
          context_extra: context.extra
        }

        defaults
          .merge(extra)
          .reject { |_key, value| value.blank? }
      end

      def logger
        @logger ||= Logger.build.with_entity(context.entity)
      end

      def log_exception(exception, payload)
        Gitlab::ExceptionLogFormatter.format!(exception, payload)
        logger.error(structured_payload(payload))
      end

      def structured_payload(payload = {})
        context = Gitlab::ApplicationContext.current.merge(
          'class' => self.class.name
        )

        payload.stringify_keys.merge(context)
      end

      def refresh_entity_and_import
        context.entity.touch
        context.bulk_import.touch
      end

      def set_source_objects_counter
        # Export status is cached for 24h and read from Redis at this point
        export_status = ExportStatus.new(tracker, tracker.importing_relation)

        ObjectCounter.set(tracker, ObjectCounter::SOURCE_COUNTER, export_status.total_objects_count)
      end

      def increment_fetched_objects_counter
        ObjectCounter.increment(tracker, ObjectCounter::FETCHED_COUNTER)
      end

      def increment_imported_objects_counter
        ObjectCounter.increment(tracker, ObjectCounter::IMPORTED_COUNTER)
      end
    end
  end
end
