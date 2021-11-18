# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ProtectedBranchesPipeline
        include NdjsonPipeline

        relation_name 'protected_branches'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
      end
    end
  end
end
