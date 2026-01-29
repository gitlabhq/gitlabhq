# frozen_string_literal: true

module Authz
  module PermissionGroups
    class Category
      include Authz::Concerns::YamlPermission

      BASE_PATH = 'config/authz/permission_groups/assignable_permissions'

      class << self
        def config_path
          Rails.root.join(BASE_PATH, '*', '_metadata.yml').to_s
        end

        private

        def resource_identifier(_, file_path)
          relative_path = file_path.split(BASE_PATH).last
          File.dirname(relative_path).delete_prefix('/').to_sym
        end
      end
    end
  end
end
