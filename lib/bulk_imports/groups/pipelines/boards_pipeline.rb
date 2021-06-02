# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class BoardsPipeline
        include NdjsonPipeline

        relation_name 'boards'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
