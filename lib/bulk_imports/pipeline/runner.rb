# frozen_string_literal: true

module BulkImports
  module Pipeline
    module Runner
      extend ActiveSupport::Concern

      included do
        private

        def extractors
          @extractors ||= self.class.extractors.map(&method(:instantiate))
        end

        def transformers
          @transformers ||= self.class.transformers.map(&method(:instantiate))
        end

        def loaders
          @loaders ||= self.class.loaders.map(&method(:instantiate))
        end

        def pipeline_name
          @pipeline ||= self.class.name
        end

        def instantiate(class_config)
          class_config[:klass].new(class_config[:options])
        end
      end

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
