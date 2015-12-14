require 'gitlab/markdown'

module Gitlab
  module Markdown
    class AtomPipeline < FullPipeline
      def self.transform_context(context)
        super(context).merge( 
          only_path: false, 
          xhtml: true 
        )
      end
    end
  end
end
