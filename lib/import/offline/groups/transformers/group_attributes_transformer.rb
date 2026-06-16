# frozen_string_literal: true

module Import
  module Offline
    module Groups
      module Transformers
        class GroupAttributesTransformer
          include ::BulkImports::PathNormalization
          include ::BulkImports::Uniquify

          def transform(context, data)
            return unless data

            import_entity = context.entity

            if import_entity.destination_namespace.present?
              namespace = Namespace.find_by_full_path(import_entity.destination_namespace)
            end

            path = normalize_path(import_entity.destination_slug)

            {
              name: uniquify(namespace, data['name'], :name),
              path: uniquify(namespace, path, :path),
              description: data['description'],
              visibility_level: allowed_visibility_level(data['visibility_level'], namespace),
              project_creation_level: data['project_creation_level'],
              subgroup_creation_level: data['subgroup_creation_level'],
              emails_enabled: data['emails_enabled'],
              lfs_enabled: data['lfs_enabled'],
              membership_lock: data['membership_lock'],
              mentions_disabled: data['mentions_disabled'],
              share_with_group_lock: data['share_with_group_lock'],
              parent_id: namespace&.id,
              require_two_factor_authentication: data['require_two_factor_authentication'],
              two_factor_grace_period: data['two_factor_grace_period'],
              request_access_enabled: data['request_access_enabled'],
              importing: true
            }.compact.with_indifferent_access
          end

          private

          def allowed_visibility_level(level, namespace)
            namespace_level = namespace&.visibility_level
            lowest_level = [level, namespace_level].compact.min

            Gitlab::VisibilityLevel.closest_allowed_level(lowest_level)
          end
        end
      end
    end
  end
end
