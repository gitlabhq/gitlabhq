# frozen_string_literal: true

module Authz
  module PermissionGroups
    class Assignable
      include Authz::Concerns::YamlPermission
      include Gitlab::Utils::StrongMemoize

      BASE_PATH = 'config/authz/permission_groups/assignable_permissions'

      class << self
        def all_permissions
          definitions.flat_map(&:permissions).uniq
        end

        def for_permission(permission)
          definitions.filter { |a| a.permissions.include?(permission) }
        end

        def config_path
          Rails.root.join(BASE_PATH, '**/[a-z]?*.yml')
        end

        def definitions
          all.values
        end
      end

      def permissions
        Array(definition[:permissions]).map(&:to_sym).uniq
      end

      def category
        source_file                     # path/to/<base_path>/**/resource/action.yml'
          .split(self.class::BASE_PATH) # [..., '**/resource/action.yml']
          .last                         # '**/resource/action.yml'
          .split('/').reverse[2]        # ['action.yml', 'resource', ...]
      end

      def category_name
        category_definition&.name || category.titlecase
      end

      private

      def category_definition
        ::Authz::PermissionGroups::Category.get(category)
      end
      strong_memoize_attr :category_definition

      def resource_definition
        ::Authz::PermissionGroups::Resource.get("#{category}/#{resource}")
      end
      strong_memoize_attr :resource_definition
    end
  end
end
