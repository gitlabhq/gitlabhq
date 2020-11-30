# frozen_string_literal: true

module BulkImports
  module Pipeline
    module Runner
      extend ActiveSupport::Concern

      def run(context)
        info(context, message: "Pipeline started", pipeline: pipeline_name)

        extractors.each do |extractor|
          extractor.extract(context).each do |entry|
            info(context, extractor: extractor.class.name)

            transformers.each do |transformer|
              info(context, transformer: transformer.class.name)
              entry = transformer.transform(context, entry)
            end

            loaders.each do |loader|
              info(context, loader: loader.class.name)
              loader.load(context, entry)
            end
          end
        end

        after_run.call(context) if after_run.present?
      end

      private # rubocop:disable Lint/UselessAccessModifier

      def info(context, extra = {})
        logger.info({
          entity: context.entity.id,
          entity_type: context.entity.source_type
        }.merge(extra))
      end

      def logger
        @logger ||= Gitlab::Import::Logger.build
      end
    end
  end
end
