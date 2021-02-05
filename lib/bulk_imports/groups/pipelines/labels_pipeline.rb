# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class LabelsPipeline
        include Pipeline

        extractor BulkImports::Common::Extractors::GraphqlExtractor,
          query: BulkImports::Groups::Graphql::GetLabelsQuery

        transformer Common::Transformers::ProhibitedAttributesTransformer

        loader BulkImports::Groups::Loaders::LabelsLoader

        def after_run(context, extracted_data)
          context.entity.update_tracker_for(
            relation: :labels,
            has_next_page: extracted_data.has_next_page?,
            next_page: extracted_data.next_page
          )

          if extracted_data.has_next_page?
            run(context)
          end
        end
      end
    end
  end
end
