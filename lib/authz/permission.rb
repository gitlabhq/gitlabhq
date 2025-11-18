# frozen_string_literal: true

module Authz
  class Permission
    include Authz::Concerns::YamlPermission

    class << self
      def all_for_tokens
        permissions_for_tokens_in_groups = PermissionGroup.available_for_tokens.flat_map(&:permissions)
        permissions_for_tokens_not_in_groups = available_for_tokens.reject do |p|
          permissions_for_tokens_in_groups.include?(p.name.to_sym)
        end

        PermissionGroup.available_for_tokens + permissions_for_tokens_not_in_groups
      end

      private

      def config_path
        Rails.root.join("config/authz/permissions/**/*.yml")
      end
    end

    def action
      return definition[:action] if definition[:action]
      return name.delete_suffix("_#{resource}") if definition[:resource]

      name.split('_')[0]
    end

    def resource
      return definition[:resource] if definition[:resource]
      return name.delete_prefix("#{action}_") if definition[:action]

      name.split('_', 2)[1]
    end

    def boundaries
      definition[:boundaries] || []
    end

    def feature_category
      definition[:feature_category]
    end
  end
end
