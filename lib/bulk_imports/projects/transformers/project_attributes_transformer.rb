# frozen_string_literal: true

module BulkImports
  module Projects
    module Transformers
      class ProjectAttributesTransformer
        PROJECT_IMPORT_TYPE = 'gitlab_project_migration'

        def transform(context, data)
          project = {}
          entity = context.entity
          visibility = data.delete('visibility')

          project[:name] = entity.destination_name
          project[:path] = entity.destination_name.parameterize
          project[:created_at] = data['created_at']
          project[:import_type] = PROJECT_IMPORT_TYPE
          project[:visibility_level] = Gitlab::VisibilityLevel.string_options[visibility] if visibility.present?
          project[:namespace_id] = Namespace.find_by_full_path(entity.destination_namespace)&.id if entity.destination_namespace.present?

          project
        end
      end
    end
  end
end
