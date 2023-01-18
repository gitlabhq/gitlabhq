# frozen_string_literal: true

module BulkImports
  module Groups
    module Transformers
      class GroupAttributesTransformer
        include BulkImports::VisibilityLevel

        # rubocop: disable Style/IfUnlessModifier
        def transform(context, data)
          import_entity = context.entity

          if import_entity.destination_namespace.present?
            namespace = Namespace.find_by_full_path(import_entity.destination_namespace)
          end

          params = {
            'name' => group_name(namespace, data),
            'path' => import_entity.destination_slug.parameterize,
            'description' => data['description'],
            'lfs_enabled' => data['lfs_enabled'],
            'emails_disabled' => data['emails_disabled'],
            'mentions_disabled' => data['mentions_disabled'],
            'share_with_group_lock' => data['share_with_group_lock']
          }

          if namespace.present?
            params['parent_id'] = namespace.id
          end

          if data.has_key?('two_factor_grace_period')
            params['two_factor_grace_period'] = data['two_factor_grace_period']
          end

          if data.has_key?('request_access_enabled')
            params['request_access_enabled'] = data['request_access_enabled']
          end

          if data.has_key?('require_two_factor_authentication')
            params['require_two_factor_authentication'] = data['require_two_factor_authentication']
          end

          if data.has_key?('project_creation_level')
            params['project_creation_level'] =
              Gitlab::Access.project_creation_string_options[data['project_creation_level']]
          end

          if data.has_key?('subgroup_creation_level')
            params['subgroup_creation_level'] =
              Gitlab::Access.subgroup_creation_string_options[data['subgroup_creation_level']]
          end

          if data.has_key?('visibility')
            params['visibility_level'] = visibility_level(import_entity, namespace, data['visibility'])
          end

          params.with_indifferent_access
        end
        # rubocop: enable Style/IfUnlessModifier

        private

        def group_name(namespace, data)
          if namespace.present?
            namespace_children_names = namespace.children.pluck(:name) # rubocop: disable CodeReuse/ActiveRecord

            if namespace_children_names.include?(data['name'])
              data['name'] = Uniquify.new(1).string(-> (counter) { "#{data['name']}(#{counter})" }) do |base|
                namespace_children_names.include?(base)
              end
            end
          end

          data['name']
        end
      end
    end
  end
end
