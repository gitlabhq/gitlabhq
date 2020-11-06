# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class SubgroupEntitiesPipeline
        include Pipeline

        extractor BulkImports::Groups::Extractors::SubgroupsExtractor
        transformer BulkImports::Groups::Transformers::SubgroupsToEntitiesTransformer
        loader BulkImports::Common::Loaders::EntitiesLoader
      end
    end
  end
end
