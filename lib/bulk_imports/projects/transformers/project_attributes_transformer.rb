# frozen_string_literal: true

module BulkImports
  module Projects
    module Transformers
      class ProjectAttributesTransformer
        include BulkImports::VisibilityLevel
        include BulkImports::PathNormalization
        include BulkImports::Uniquify

        PROJECT_IMPORT_TYPE = 'gitlab_project_migration'

        NamespaceNotFoundError = Class.new(StandardError)

        def transform(context, data)
          project = {}
          entity = context.entity
          namespace = entity.bulk_import.organization.namespaces.find_by_full_path(entity.destination_namespace)

          unless namespace
            raise(
              NamespaceNotFoundError,
              "Destination namespace '#{entity.destination_namespace}' not found in the import organization"
            )
          end

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
