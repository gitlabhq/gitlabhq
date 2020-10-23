# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class GroupPipeline
        include Pipeline

        extractor Common::Extractors::GraphqlExtractor, query: Graphql::GetGroupQuery

        transformer Common::Transformers::GraphqlCleanerTransformer
        transformer Common::Transformers::UnderscorifyKeysTransformer
        transformer Groups::Transformers::GroupAttributesTransformer

        loader Groups::Loaders::GroupLoader
      end
    end
  end
end
