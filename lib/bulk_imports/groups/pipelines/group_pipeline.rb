# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class GroupPipeline
        include Pipeline

        abort_on_failure!

        extractor Common::Extractors::GraphqlExtractor, query: Graphql::GetGroupQuery

        transformer Common::Transformers::HashKeyDigger, key_path: %w[data group]
        transformer Common::Transformers::UnderscorifyKeysTransformer
        transformer Groups::Transformers::GroupAttributesTransformer

        loader Groups::Loaders::GroupLoader
      end
    end
  end
end
