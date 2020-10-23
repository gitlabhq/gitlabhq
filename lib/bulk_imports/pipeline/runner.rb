# frozen_string_literal: true

module BulkImports
  module Pipeline
    module Runner
      extend ActiveSupport::Concern

      included do
        attr_reader :extractors, :transformers, :loaders

        def initialize
          @extractors = self.class.extractors.map(&method(:instantiate))
          @transformers = self.class.transformers.map(&method(:instantiate))
          @loaders = self.class.loaders.map(&method(:instantiate))

          super
        end

        def run(context)
          extractors.each do |extractor|
            extractor.extract(context).each do |entry|
              transformers.each do |transformer|
                entry = transformer.transform(context, entry)
              end

              loaders.each do |loader|
                loader.load(context, entry)
              end
            end
          end
        end

        def instantiate(class_config)
          class_config[:klass].new(class_config[:options])
        end
      end
    end
  end
end
