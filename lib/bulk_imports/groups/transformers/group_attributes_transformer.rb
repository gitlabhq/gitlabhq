# frozen_string_literal: true

module BulkImports
  module Groups
    module Transformers
      class GroupAttributesTransformer
        include BulkImports::VisibilityLevel
        include BulkImports::PathNormalization
        include BulkImports::Uniquify

        # rubocop: disable Style/IfUnlessModifier
        def transform(context, data)
          import_entity = context.entity

          if import_entity.destination_namespace.present?
            namespace = Namespace.find_by_full_path(import_entity.destination_namespace)
          end

          path = normalize_path(import_entity.destination_slug)

          params = {
            'name' => uniquify(namespace, data['name'], :name),
            'path' => uniquify(namespace, path, :path),
            'description' => data['description'],
            'lfs_enabled' => data['lfs_enabled'],
            'emails_enabled' => !data['emails_disabled'],
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
      end
    end
  end
end
