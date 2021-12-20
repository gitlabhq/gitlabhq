# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ProjectFeaturePipeline
        include NdjsonPipeline

        relation_name 'project_feature'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
