module Banzai
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    def initialize
      @texts_and_contexts = []
    end

    def analyze(text, context = {})
      @texts_and_contexts << { text: text, context: context }
    end

    def references(type, project, current_user = nil)
      context = RenderContext.new(project, current_user)
      processor = Banzai::ReferenceParser[type].new(context)

      processor.process(html_documents)
    end

    def reset_memoized_values
      @html_documents     = nil
      @texts_and_contexts = []
    end

    private

    def html_documents
      # This ensures that we don't memoize anything until we have a number of
      # text blobs to parse.
      return [] if @texts_and_contexts.empty?

      @html_documents ||= Renderer.cache_collection_render(@texts_and_contexts)
        .map { |html| Nokogiri::HTML.fragment(html) }
    end
  end
end
