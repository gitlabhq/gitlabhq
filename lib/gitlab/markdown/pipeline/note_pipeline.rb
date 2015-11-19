require 'gitlab/markdown'

module Gitlab
  module Markdown
    class NotePipeline < FullPipeline
      def self.transform_context(context)
        super(context).merge( 
          # TableOfContentsFilter
          no_header_anchors: true
        )
      end
    end
  end
end
