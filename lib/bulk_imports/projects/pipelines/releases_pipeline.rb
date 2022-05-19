# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ReleasesPipeline
        include NdjsonPipeline

        relation_name 'releases'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
