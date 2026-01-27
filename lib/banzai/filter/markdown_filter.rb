# frozen_string_literal: true

module Banzai
  module Filter
    class MarkdownFilter < HTML::Pipeline::TextFilter
      GLFM_ENGINE    = :glfm_markdown # gitlab-glfm-markdown/Comrak
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
        # "start_line:start_column-end_line:end_column" into 0-based
        # attributes. For example, "1:10-14:1" becomes
        # {
        #   start: { line: 0, column: 9 },
        #   end: { line: 13, column: 0 }
        # }
        def parse_sourcepos(sourcepos)
          start_pos, end_pos = sourcepos&.split('-')
          start_line, start_column = start_pos&.split(':')
          end_line, end_column = end_pos&.split(':')

          return unless start_line && start_column && end_line && end_column

          {
            start: { line: [1, start_line.to_i].max - 1, column: [1, start_column.to_i].max - 1 },
            end: { line: [1, end_line.to_i].max - 1, column: [1, end_column.to_i].max - 1 }
          }
        end

        def glfm_markdown?(context)
          (context[:markdown_engine] || DEFAULT_ENGINE) == GLFM_ENGINE
        end
      end
    end
  end
end
