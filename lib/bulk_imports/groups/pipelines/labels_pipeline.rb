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

        def after_run(extracted_data)
          context.entity.update_tracker_for(
            relation: :labels,
            has_next_page: extracted_data.has_next_page?,
            next_page: extracted_data.next_page
          )

          if extracted_data.has_next_page?
            run
          end
        end
      end
    end
  end
end
