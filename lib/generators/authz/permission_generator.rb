# frozen_string_literal: true

require 'rails/generators'

module Authz
  class PermissionGenerator < Rails::Generators::NamedBase
    PERMISSION_DIR = 'config/authz/permissions'

    desc 'This generator creates the definition file for a new permission'

    source_root File.expand_path('../../../generator_templates/authz', __dir__)

    class_option :action, type: :string, optional: true, desc: "Override the default permission action name"
    class_option :resource, type: :string, optional: true, desc: "Override the default permission resource name"

    def validate!
      @action = get_action
      @resource = get_resource

      return if @action && @resource

      abort "Permission must be in the format action_resource[_subresource]"
    end

    def create_permission_definition
      template("permission_definition.yml.erb", file_path)
    end

    private

    def file_path
      File.join(PERMISSION_DIR, @resource, "#{@action}.yml")
    end

    def get_action
      return options[:action] if options[:action]
      return name.delete_suffix("_#{options[:resource]}") if options[:resource]

      name.split('_')[0]
    end

    def get_resource
      return options[:resource] if options[:resource]
      return name.delete_prefix("#{options[:action]}_") if options[:action]

      name.split('_', 2)[1]
    end
  end
end
