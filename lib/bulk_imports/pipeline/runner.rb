# frozen_string_literal: true

module BulkImports
  module Pipeline
    module Runner
      extend ActiveSupport::Concern

      MarkedAsFailedError = Class.new(StandardError)

      def run(context)
        raise MarkedAsFailedError if marked_as_failed?(context)

        info(context, message: 'Pipeline started', pipeline_class: pipeline)

        extractors.each do |extractor|
          data = run_pipeline_step(:extractor, extractor.class.name, context) do
            extractor.extract(context)
          end

          if data && data.respond_to?(:each)
            data.each do |entry|
              transformers.each do |transformer|
                entry = run_pipeline_step(:transformer, transformer.class.name, context) do
                  transformer.transform(context, entry)
                end
              end

              loaders.each do |loader|
                run_pipeline_step(:loader, loader.class.name, context) do
                  loader.load(context, entry)
                end
              end
            end
          end
        end

        after_run.call(context) if after_run.present?
      rescue MarkedAsFailedError
        log_skip(context)
      end

      private # rubocop:disable Lint/UselessAccessModifier

      def run_pipeline_step(type, class_name, context)
        raise MarkedAsFailedError if marked_as_failed?(context)

        info(context, type => class_name)

        yield
      rescue MarkedAsFailedError
        log_skip(context, type => class_name)
      rescue => e
        log_import_failure(e, context)

        mark_as_failed(context) if abort_on_failure?
      end

      def mark_as_failed(context)
        warn(context, message: 'Pipeline failed', pipeline_class: pipeline)

        context.entity.fail_op!
      end

      def marked_as_failed?(context)
        return true if context.entity.failed?

        false
      end

      def log_skip(context, extra = {})
        log = {
          message: 'Skipping due to failed pipeline status',
          pipeline_class: pipeline
        }.merge(extra)

        info(context, log)
      end

      def log_import_failure(exception, context)
        attributes = {
          bulk_import_entity_id: context.entity.id,
          pipeline_class: pipeline,
          exception_class: exception.class.to_s,
          exception_message: exception.message.truncate(255),
          correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
        }

        BulkImports::Failure.create(attributes)
      end

      def warn(context, extra = {})
        logger.warn(log_base_params(context).merge(extra))
      end

      def info(context, extra = {})
        logger.info(log_base_params(context).merge(extra))
      end

      def log_base_params(context)
        {
          bulk_import_entity_id: context.entity.id,
          bulk_import_entity_type: context.entity.source_type
        }
      end

      def logger
        @logger ||= Gitlab::Import::Logger.build
      end
    end
  end
end
