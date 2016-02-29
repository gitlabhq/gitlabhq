module Banzai
  module Pipeline
    class ReferenceUnfoldPipeline < BasePipeline
      def self.filters
        FullPipeline.filters +
        [Filter::ReferenceGathererFilter,
         Filter::ReferenceUnfoldFilter]
      end

      def self.call(text, context = {})
        context = context.merge(text: text)
        super
      end

      class << self
        alias_method :to_document, :call
        alias_method :to_html, :call
      end
    end
  end
end
