require 'gitlab/markdown'

module Gitlab
  module Markdown
    class ReferenceExtractionPipeline < Pipeline
      def self.filters
        [
          Gitlab::Markdown::ReferenceGathererFilter
        ]
      end
    end
  end
end
