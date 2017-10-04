module Banzai
  module Filter
    class MarkdownFilter < HTML::Pipeline::TextFilter
      # https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
      REDCARPET_OPTIONS = {
        fenced_code_blocks:  true,
        footnotes:           true,
        lax_spacing:         true,
        no_intra_emphasis:   true,
        space_after_headers: true,
        strikethrough:       true,
        superscript:         true,
        tables:              true
      }.freeze

      def initialize(text, context = nil, result = nil)
        super text, context, result
        @text = @text.delete "\r"
      end

      def call
        html = self.class.renderer.render(@text)
        html.rstrip!
        html
      end

      def self.renderer
        Thread.current[:banzai_markdown_renderer] ||= begin
          renderer = Banzai::Renderer::HTML.new
          Redcarpet::Markdown.new(renderer, REDCARPET_OPTIONS)
        end
      end
    end
  end
end
