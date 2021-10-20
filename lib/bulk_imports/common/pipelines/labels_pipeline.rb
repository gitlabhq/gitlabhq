# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class LabelsPipeline
        include NdjsonPipeline

        relation_name 'labels'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
