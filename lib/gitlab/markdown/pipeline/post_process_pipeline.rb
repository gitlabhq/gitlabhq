require 'gitlab/markdown'

module Gitlab
  module Markdown
    class PostProcessPipeline < Pipeline
      def self.filters
        [
          Gitlab::Markdown::RelativeLinkFilter, 
          Gitlab::Markdown::RedactorFilter
        ]
      end

      def self.transform_context(context)
        context.merge(
          post_process: true
        )
      end
    end
  end
end
