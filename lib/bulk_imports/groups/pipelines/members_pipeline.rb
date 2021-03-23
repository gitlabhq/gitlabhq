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
      end
    end
  end
end
