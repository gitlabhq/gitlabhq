# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class LabelsPipeline
        include Pipeline

        extractor BulkImports::Common::Extractors::GraphqlExtractor,
          query: BulkImports::Groups::Graphql::GetLabelsQuery

        transformer BulkImports::Common::Transformers::HashKeyDigger, key_path: %w[data group labels]
        transformer Common::Transformers::ProhibitedAttributesTransformer

        loader BulkImports::Groups::Loaders::LabelsLoader

        def after_run(context)
          if context.entity.has_next_page?(:labels)
            run(context)
          end
        end
      end
    end
  end
end
