# frozen_string_literal: true

module Import
  module Offline
    module Groups
      module Pipelines
        class ProjectEntitiesPipeline
          include ::BulkImports::Pipeline
          include ::BulkImports::Pipeline::HexdigestCacheStrategy

          def extract(context)
            configuration = context.offline_configuration

            projects = configuration.project_paths_for(context.entity.source_full_path)

            ::BulkImports::Pipeline::ExtractedData.new(data: projects)
          end

          def transform(context, data)
            {
              source_type: :project_entity,
              source_full_path: data['full_path'],
              destination_name: data['path'],
              destination_namespace: context.entity.group.full_path,
              parent_id: context.entity.id
            }
          end

          def load(context, data)
            context.bulk_import.entities.create!(data.merge(organization_id: context.entity.group.organization_id))
          end
        end
      end
    end
  end
end
