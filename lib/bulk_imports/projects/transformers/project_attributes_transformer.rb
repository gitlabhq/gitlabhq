# frozen_string_literal: true

module BulkImports
  module Projects
    module Transformers
      class ProjectAttributesTransformer
        include BulkImports::VisibilityLevel
        include BulkImports::PathNormalization
        include BulkImports::Uniquify

        PROJECT_IMPORT_TYPE = 'gitlab_project_migration'

        def transform(context, data)
          project = {}
          entity = context.entity
          namespace = Namespace.find_by_full_path(entity.destination_namespace)
          path = normalize_path(entity.destination_slug)

          project[:name] = uniquify(namespace, data['name'], :name)
          project[:path] = uniquify(namespace, path, :path)
          project[:created_at] = data['created_at']
          project[:import_type] = PROJECT_IMPORT_TYPE
          project[:visibility_level] = visibility_level(entity, namespace, data['visibility'])
          project[:namespace_id] = namespace.id

          project.with_indifferent_access
        end
      end
    end
  end
end
