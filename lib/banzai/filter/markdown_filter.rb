module Banzai
  module Filter
    class MarkdownFilter < HTML::Pipeline::TextFilter
      def initialize(text, context = nil, result = nil)
        super(text, context, result)

        @renderer = renderer(context[:markdown_engine]).new
        @text = @text.delete("\r")
      end

      def call
        @renderer.render(@text).rstrip
      end

      private

      DEFAULT_ENGINE = :redcarpet

      def engine(engine_from_context)
        engine_from_context ||= DEFAULT_ENGINE

        engine_from_context.to_s.classify
      end

      def renderer(engine_from_context)
        "Banzai::Filter::MarkdownEngines::#{engine(engine_from_context)}".constantize
      rescue NameError
        raise NameError, "`#{engine_from_context}` is unknown markdown engine"
      end
    end
  end
end
