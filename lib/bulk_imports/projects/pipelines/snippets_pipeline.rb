# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class SnippetsPipeline
        include NdjsonPipeline

        relation_name 'snippets'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
