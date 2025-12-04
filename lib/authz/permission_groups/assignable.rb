# frozen_string_literal: true

module Authz
  module PermissionGroups
    class Assignable
      include Authz::Concerns::YamlPermission

      BASE_PATH = 'config/authz/permission_groups/assignable_permissions'

      class << self
        def all_permissions
          definitions.flat_map(&:permissions)
        end

        def for_permission(permission)
          definitions.filter { |a| a.permissions.include?(permission) }
        end

        private

        def definitions
          all.values
        end

        def config_path
          Rails.root.join(BASE_PATH, '**/*.yml')
        end
      end

      def permissions
        definition[:permissions].map(&:to_sym).uniq
      end

      def category
        # 'path/to/app/config/authz/permission_groups/assignable_permissions/category/resource/action.yml'
        category = source_file
          .split(self.class::BASE_PATH) # [..., 'category/resource/action.yml']
          .last                         # 'category/resource/action.yml'
          .split('/').reverse[2]        # ['action.yml', 'resource', 'category'] => 'category' or ''

        category.presence || feature_category
      end
    end
  end
end
