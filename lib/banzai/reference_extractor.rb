module Banzai
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    def initialize
      @texts = []
    end

    def analyze(text, context = {})
      @texts << Renderer.render(text, context)
    end

    def references(type, project, current_user = nil)
      processor = Banzai::ReferenceParser[type].
        new(project, current_user)

      processor.process(html_documents)
    end

    private

    def html_documents
      # This ensures that we don't memoize anything until we have a number of
      # text blobs to parse.
      return [] if @texts.empty?

      @html_documents ||= @texts.map { |html| Nokogiri::HTML.fragment(html) }
    end
  end
end
