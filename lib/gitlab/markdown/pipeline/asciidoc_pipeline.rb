require 'gitlab/markdown'

module Gitlab
  module Markdown
    class AsciidocPipeline < Pipeline
      def self.filters
        [
          Gitlab::Markdown::RelativeLinkFilter
        ]
      end
    end
  end
end
