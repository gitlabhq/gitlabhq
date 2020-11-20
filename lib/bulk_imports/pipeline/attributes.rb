# frozen_string_literal: true

module BulkImports
  module Pipeline
    module Attributes
      extend ActiveSupport::Concern
      include Gitlab::ClassAttributes

      class_methods do
        def extractor(klass, options = nil)
          add_attribute(:extractors, klass, options)
        end

        def transformer(klass, options = nil)
          add_attribute(:transformers, klass, options)
        end

        def loader(klass, options = nil)
          add_attribute(:loaders, klass, options)
        end

        def after_run(&block)
          class_attributes[:after_run] = block
        end

        def add_attribute(sym, klass, options)
          class_attributes[sym] ||= []
          class_attributes[sym] << { klass: klass, options: options }
        end

        def extractors
          class_attributes[:extractors]
        end

        def transformers
          class_attributes[:transformers]
        end

        def loaders
          class_attributes[:loaders]
        end

        def after_run_callback
          class_attributes[:after_run]
        end
      end
    end
  end
end
