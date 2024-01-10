# frozen_string_literal: true

module Banzai
  module Filter
    class MarkdownFilter < HTML::Pipeline::TextFilter
      RUST_ENGINE = :glfm_markdown # glfm_markdown/comrak
      RUBY_ENGINE = :common_mark   # original commonmarker/cmark-gfm

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
        engine = context[:markdown_engine] || default_engine

        engine.to_s.classify
      end

      def default_engine
        return RUST_ENGINE if Feature.enabled?(:markdown_rust, context[:project])

        RUBY_ENGINE
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
      end
    end
  end
end
