require 'gitlab/markdown'

module Gitlab
  module Markdown
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
