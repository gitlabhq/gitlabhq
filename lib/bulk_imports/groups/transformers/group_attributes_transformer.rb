# frozen_string_literal: true

module BulkImports
  module Groups
    module Transformers
      class GroupAttributesTransformer
        def transform(context, data)
          import_entity = context.entity

          data
            .then { |data| transform_name(import_entity, data) }
            .then { |data| transform_path(import_entity, data) }
            .then { |data| transform_full_path(data) }
            .then { |data| transform_parent(context, import_entity, data) }
            .then { |data| transform_visibility_level(data) }
            .then { |data| transform_project_creation_level(data) }
            .then { |data| transform_subgroup_creation_level(data) }
        end

        private

        def transform_name(import_entity, data)
          data['name'] = import_entity.destination_name
          data
        end

        def transform_path(import_entity, data)
          data['path'] = import_entity.destination_name.parameterize
          data
        end

        def transform_full_path(data)
          data.delete('full_path')
          data
        end

        def transform_parent(context, import_entity, data)
          unless import_entity.destination_namespace.blank?
            namespace = Namespace.find_by_full_path(import_entity.destination_namespace)
            data['parent_id'] = namespace.id
          end

          data
        end

        def transform_visibility_level(data)
          visibility = data['visibility']

          return data unless visibility.present?

          data['visibility_level'] = Gitlab::VisibilityLevel.string_options[visibility]
          data.delete('visibility')
          data
        end

        def transform_project_creation_level(data)
          project_creation_level = data['project_creation_level']

          return data unless project_creation_level.present?

          data['project_creation_level'] = Gitlab::Access.project_creation_string_options[project_creation_level]
          data
        end

        def transform_subgroup_creation_level(data)
          subgroup_creation_level = data['subgroup_creation_level']

          return data unless subgroup_creation_level.present?

          data['subgroup_creation_level'] = Gitlab::Access.subgroup_creation_string_options[subgroup_creation_level]
          data
        end
      end
    end
  end
end
