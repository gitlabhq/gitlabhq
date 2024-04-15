# frozen_string_literal: true

module Banzai
  module Filter
    class MarkdownFilter < HTML::Pipeline::TextFilter
      GLFM_ENGINE    = :glfm_markdown # glfm_markdown/comrak
      CMARK_ENGINE   = :cmark         # original commonmarker/cmark-gfm
      DEFAULT_ENGINE = GLFM_ENGINE

      def initialize(text, context = nil, result = nil)
        super(text, context, result)

        @renderer = render_engine.new(@context)
        @text = @text.delete("\r")
      end

      def call
        @renderer.render(@text).rstrip
      end

      def render_engine
        "Banzai::Filter::MarkdownEngines::#{engine}".constantize
      rescue NameError
        raise NameError, "`#{engine_class}` is unknown markdown engine"
      end

      private

      def engine
        engine = context[:markdown_engine] || DEFAULT_ENGINE

        engine.to_s.classify
      end

      class << self
        # Parses string representing a sourcepos in format
        # "start_row:start_column-end_row:end_column" into 0-based
        # attributes. For example, "1:10-14:1" becomes
        # {
        #   start: { row: 0, col: 9 },
        #   end: { row: 13, col: 0 }
        # }
        def parse_sourcepos(sourcepos)
          start_pos, end_pos = sourcepos&.split('-')
          start_row, start_col = start_pos&.split(':')
          end_row, end_col = end_pos&.split(':')

          return unless start_row && start_col && end_row && end_col

          {
            start: { row: [1, start_row.to_i].max - 1, col: [1, start_col.to_i].max - 1 },
            end: { row: [1, end_row.to_i].max - 1, col: [1, end_col.to_i].max - 1 }
          }
        end

        def glfm_markdown?(context)
          (context[:markdown_engine] || DEFAULT_ENGINE) == GLFM_ENGINE
        end
      end
    end
  end
end
