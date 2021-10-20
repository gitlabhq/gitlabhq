# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class IssuesPipeline
        include NdjsonPipeline

        relation_name 'issues'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
