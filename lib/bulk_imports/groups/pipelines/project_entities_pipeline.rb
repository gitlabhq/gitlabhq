# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class ProjectEntitiesPipeline
        include Pipeline
        include HexdigestCacheStrategy

        extractor Common::Extractors::GraphqlExtractor, query: Graphql::GetProjectsQuery
        transformer Common::Transformers::ProhibitedAttributesTransformer

        def transform(context, data)
          {
            source_type: :project_entity,
            source_full_path: data['full_path'],
            destination_name: data['path'],
            destination_namespace: context.entity.group.full_path,
            parent_id: context.entity.id,
            source_xid: GlobalID.parse(data['id']).model_id
          }
        end

        def load(context, data)
          context.bulk_import.entities.create!(data.merge(organization_id: context.entity.group.organization_id))
        end
      end
    end
  end
end
