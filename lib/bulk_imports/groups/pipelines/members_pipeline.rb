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

        def load(context, data)
          return unless data

          context.group.members.create!(data)
        end

        def after_run(extracted_data)
          tracker.update(
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
