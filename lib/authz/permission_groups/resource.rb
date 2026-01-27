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

        def load_all
          load_files_to_hash(config_path) do |file, content|
            resource_identifier = extract_resource_identifier(file)
            [resource_identifier.to_sym, new(content, file)]
          end
        end

        def extract_resource_identifier(file)
          relative_path = file.split(BASE_PATH).last
          File.dirname(relative_path).delete_prefix('/')
        end
      end
    end
  end
end
