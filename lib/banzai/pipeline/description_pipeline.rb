require 'banzai'

module Banzai
  module Pipeline
    class DescriptionPipeline < FullPipeline
      def self.transform_context(context)
        super(context).merge(
          # SanitizationFilter
          inline_sanitization: true
        )
      end
    end
  end
end
