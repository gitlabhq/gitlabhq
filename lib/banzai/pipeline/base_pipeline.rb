module Banzai
  module Pipeline
    class BasePipeline
      def self.filters
        FilterArray[]
      end

      def self.transform_context(context)
        context
      end

      def self.html_pipeline
        @html_pipeline ||= HTML::Pipeline.new(filters)
      end

      class << self
        %i(call to_document to_html).each do |meth|
          define_method(meth) do |text, context|
            context = transform_context(context)

            html_pipeline.__send__(meth, text, context) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end
end
