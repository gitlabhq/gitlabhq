# frozen_string_literal: true

module BulkImports
  module Pipeline
    module Runner
      extend ActiveSupport::Concern

      MarkedAsFailedError = Class.new(StandardError)

      def run
        raise MarkedAsFailedError if marked_as_failed?

        info(message: 'Pipeline started')

        extracted_data = extracted_data_from

        extracted_data&.each do |entry|
          transformers.each do |transformer|
            entry = run_pipeline_step(:transformer, transformer.class.name) do
              transformer.transform(context, entry)
            end
          end

          run_pipeline_step(:loader, loader.class.name) do
            loader.load(context, entry)
          end
        end

        if respond_to?(:after_run)
          run_pipeline_step(:after_run) do
            after_run(extracted_data)
          end
        end

        info(message: 'Pipeline finished')
      rescue MarkedAsFailedError
        log_skip
      end

      private # rubocop:disable Lint/UselessAccessModifier

      def run_pipeline_step(step, class_name = nil)
        raise MarkedAsFailedError if marked_as_failed?

        info(pipeline_step: step, step_class: class_name)

        yield
      rescue MarkedAsFailedError
        log_skip(step => class_name)
      rescue => e
        log_import_failure(e, step)

        mark_as_failed if abort_on_failure?

        nil
      end

      def extracted_data_from
        run_pipeline_step(:extractor, extractor.class.name) do
          extractor.extract(context)
        end
      end

      def mark_as_failed
        warn(message: 'Pipeline failed', pipeline_class: pipeline)

        context.entity.fail_op!
      end

      def marked_as_failed?
        return true if context.entity.failed?

        false
      end

      def log_skip(extra = {})
        log = {
          message: 'Skipping due to failed pipeline status',
          pipeline_class: pipeline
        }.merge(extra)

        info(log)
      end

      def log_import_failure(exception, step)
        attributes = {
          bulk_import_entity_id: context.entity.id,
          pipeline_class: pipeline,
          pipeline_step: step,
          exception_class: exception.class.to_s,
          exception_message: exception.message.truncate(255),
          correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
        }

        BulkImports::Failure.create(attributes)
      end

      def warn(extra = {})
        logger.warn(log_params(extra))
      end

      def info(extra = {})
        logger.info(log_params(extra))
      end

      def log_params(extra)
        defaults = {
          bulk_import_entity_id: context.entity.id,
          bulk_import_entity_type: context.entity.source_type,
          pipeline_class: pipeline
        }

        defaults.merge(extra).compact
      end

      def logger
        @logger ||= Gitlab::Import::Logger.build
      end
    end
  end
end
