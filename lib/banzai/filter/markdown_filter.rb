# frozen_string_literal: true

module Banzai
  module Filter
    class MarkdownFilter < HTML::Pipeline::TextFilter
      DEFAULT_ENGINE = :common_mark

      def initialize(text, context = nil, result = nil)
        super(text, context, result)

        @renderer = self.class.render_engine(context[:markdown_engine]).new(context)
        @text = @text.delete("\r")
      end

      def call
        @renderer.render(@text).rstrip
      end

      class << self
        def render_engine(engine_from_context)
          "Banzai::Filter::MarkdownEngines::#{engine(engine_from_context)}".constantize
        rescue NameError
          raise NameError, "`#{engine_from_context}` is unknown markdown engine"
        end

        private

        def engine(engine_from_context)
          engine_from_context ||= DEFAULT_ENGINE

          engine_from_context.to_s.classify
        end
      end
    end
  end
end
