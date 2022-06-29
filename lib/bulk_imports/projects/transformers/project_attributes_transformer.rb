# frozen_string_literal: true

module BulkImports
  module Projects
    module Transformers
      class ProjectAttributesTransformer
        PROJECT_IMPORT_TYPE = 'gitlab_project_migration'

        def transform(context, data)
          entity = context.entity
          visibility = data.delete('visibility')

          data['name'] = entity.destination_name
          data['path'] = entity.destination_name.parameterize
          data['import_type'] = PROJECT_IMPORT_TYPE
          data['visibility_level'] = Gitlab::VisibilityLevel.string_options[visibility] if visibility.present?
          data['namespace_id'] = Namespace.find_by_full_path(entity.destination_namespace)&.id if entity.destination_namespace.present?

          data.transform_keys!(&:to_sym)
        end
      end
    end
  end
end
