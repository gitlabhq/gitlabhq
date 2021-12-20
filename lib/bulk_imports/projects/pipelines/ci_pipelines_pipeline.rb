# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class CiPipelinesPipeline
        include NdjsonPipeline

        relation_name 'ci_pipelines'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
