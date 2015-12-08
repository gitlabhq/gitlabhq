require 'gitlab/markdown'

module Gitlab
  module Markdown
    class PlainMarkdownPipeline < Pipeline
      def self.filters
        [
          Gitlab::Markdown::MarkdownFilter
        ]
      end
    end
  end
end
