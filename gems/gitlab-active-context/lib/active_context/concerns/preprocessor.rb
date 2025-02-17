# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Preprocessor
      def preprocessors
        @preprocessors ||= []
      end

      def add_preprocessor(name, &block)
        preprocessors << { name: name, block: block }
      end

      def preprocess(refs)
        refs_by_class = refs.group_by(&:class)
        refs_by_class.flat_map do |klass, class_refs|
          klass.preprocessors.reduce(class_refs) do |processed_refs, preprocessor|
            preprocessor[:block].call(processed_refs)
          end
        end
      end
    end
  end
end
