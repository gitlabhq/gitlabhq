# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class SubgroupEntitiesPipeline
        include Pipeline
        include HexdigestCacheStrategy

        extractor BulkImports::Groups::Extractors::SubgroupsExtractor
        transformer Common::Transformers::ProhibitedAttributesTransformer
        transformer BulkImports::Groups::Transformers::SubgroupToEntityTransformer

        def load(context, data)
          context.bulk_import.entities.create!(data)
        end
      end
    end
  end
end
