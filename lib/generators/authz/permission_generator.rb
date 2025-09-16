# frozen_string_literal: true

require 'rails/generators'

module Authz
  class PermissionGenerator < Rails::Generators::NamedBase
    PERMISSION_DIR = 'config/authz/permissions'

    desc 'This generator creates the definition file for a new permission'

    source_root File.expand_path('../../../generator_templates/authz', __dir__)

    def validate!
      action, resource = name.split('_', 2)

      return if action && resource

      abort "Permission must be in the format action_resource[_subresource]"
    end

    def create_permission_definition
      template("permission_definition.yml", file_path)
    end

    private

    def file_path
      action, resource = name.split('_', 2)

      File.join(PERMISSION_DIR, resource, "#{action}.yml")
    end
  end
end
