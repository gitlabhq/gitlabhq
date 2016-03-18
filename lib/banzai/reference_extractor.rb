module Banzai
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    class << self
      LAZY_KEY = :banzai_reference_extractor_lazy

      def lazy?
        Thread.current[LAZY_KEY]
      end

      def lazily(values = nil, &block)
        return (values || block.call).uniq if lazy?

        begin
          Thread.current[LAZY_KEY] = true

          values ||= block.call

          Banzai::LazyReference.load(values.uniq).uniq
        ensure
          Thread.current[LAZY_KEY] = false
        end
      end
    end

    def initialize
      @texts = []
    end

    def analyze(text, context = {})
      @texts << Renderer.render(text, context)
    end

    def references(type, context = {})
      filter = Banzai::Filter["#{type}_reference"]

      context.merge!(
        pipeline: :reference_extraction,

        # ReferenceGathererFilter
        reference_filter: filter
      )

      self.class.lazily do
        @texts.flat_map do |html|
          text_context = context.dup
          result = Renderer.render_result(html, text_context)
          result[:references][type]
        end.uniq
      end
    end
  end
end
