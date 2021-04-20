# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class LabelsPipeline
        include Pipeline

        extractor BulkImports::Common::Extractors::GraphqlExtractor,
          query: BulkImports::Groups::Graphql::GetLabelsQuery

        transformer Common::Transformers::ProhibitedAttributesTransformer

        def load(context, data)
          Labels::CreateService.new(data).execute(group: context.group)
        end
      end
    end
  end
end
