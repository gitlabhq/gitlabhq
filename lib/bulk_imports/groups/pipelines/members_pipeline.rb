# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class MembersPipeline
        include Pipeline

        extractor BulkImports::Common::Extractors::GraphqlExtractor,
          query: BulkImports::Groups::Graphql::GetMembersQuery

        transformer Common::Transformers::ProhibitedAttributesTransformer
        transformer BulkImports::Groups::Transformers::MemberAttributesTransformer

        loader BulkImports::Groups::Loaders::MembersLoader

        def after_run(context, extracted_data)
          context.entity.update_tracker_for(
            relation: :group_members,
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
