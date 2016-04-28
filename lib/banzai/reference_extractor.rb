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

    def references(type, project, current_user = nil, author = nil)
      processor = Banzai::ReferenceParser[type].
        new(project, current_user, author)

      refs = Set.new

      @texts.each do |html|
        doc = Nokogiri::HTML.fragment(html)

        processor.process(doc).each do |ref|
          refs << ref
        end
      end

      refs.to_a
    end
  end
end
