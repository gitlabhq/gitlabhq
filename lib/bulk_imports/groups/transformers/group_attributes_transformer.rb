# frozen_string_literal: true

module BulkImports
  module Groups
    module Transformers
      class GroupAttributesTransformer
        def transform(context, data)
          import_entity = context.entity

          if import_entity.destination_namespace.present?
            namespace = Namespace.find_by_full_path(import_entity.destination_namespace)
          end

          data
            .then { |data| transform_name(import_entity, namespace, data) }
            .then { |data| transform_path(import_entity, data) }
            .then { |data| transform_full_path(data) }
            .then { |data| transform_parent(context, import_entity, namespace, data) }
            .then { |data| transform_visibility_level(data) }
            .then { |data| transform_project_creation_level(data) }
            .then { |data| transform_subgroup_creation_level(data) }
        end

        private

        def transform_name(import_entity, namespace, data)
          if namespace.present?
            namespace_children_names = namespace.children.pluck(:name) # rubocop: disable CodeReuse/ActiveRecord

            if namespace_children_names.include?(data['name'])
              data['name'] = Uniquify.new(1).string(-> (counter) { "#{data['name']}(#{counter})" }) do |base|
                namespace_children_names.include?(base)
              end
            end
          end

          data
        end

        def transform_path(import_entity, data)
          data['path'] = import_entity.destination_slug.parameterize
          data
        end

        def transform_full_path(data)
          data.delete('full_path')
          data
        end

        def transform_parent(context, import_entity, namespace, data)
          data['parent_id'] = namespace.id if namespace.present?

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
