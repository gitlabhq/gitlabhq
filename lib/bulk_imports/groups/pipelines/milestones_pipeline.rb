# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class MilestonesPipeline
        include Pipeline

        extractor BulkImports::Common::Extractors::GraphqlExtractor,
          query: BulkImports::Groups::Graphql::GetMilestonesQuery

        transformer Common::Transformers::ProhibitedAttributesTransformer

        def load(context, data)
          return unless data

          raise ::BulkImports::Pipeline::NotAllowedError unless authorized?

          context.group.milestones.create!(data)
        end

        private

        def authorized?
          context.current_user.can?(:admin_milestone, context.group)
        end
      end
    end
  end
end
