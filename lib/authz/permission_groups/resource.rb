# frozen_string_literal: true

module Authz
  module PermissionGroups
    class Resource
      include Authz::Concerns::YamlPermission

      BASE_PATH = 'config/authz/permission_groups/assignable_permissions'

      class << self
        def config_path
          Rails.root.join(BASE_PATH, '**', '_metadata.yml').to_s
        end

        private

        def resource_identifier(_, file_path)
          relative_path = file_path.split(BASE_PATH).last
          File.dirname(relative_path).delete_prefix('/').to_sym
        end
      end

      def name
        File.basename(File.dirname(source_file))
      end

      def resource_name
        definition[:name] || name.titlecase
      end
    end
  end
end
