# frozen_string_literal: true

module Authz
  class Permission
    class << self
      def all
        @permissions ||= load_permissions
      end

      def get(name)
        all[name.to_sym]
      end

      def defined?(name)
        all.key?(name.to_sym)
      end

      private

      def load_permissions
        permissions = {}

        Dir.glob(permission_path).each do |file|
          permission = load_from_file(file)
          permissions[permission.name.to_sym] = permission
        end

        permissions
      end

      def load_from_file(path)
        definition_data = File.read(path)
        definition = YAML.safe_load(definition_data)
        definition.deep_symbolize_keys!
        new(definition, path)
      end

      def permission_path
        Rails.root.join("config/authz/permissions/**/*.yml")
      end
    end

    attr_reader :definition, :source_file

    def initialize(definition, source_file)
      @definition = definition
      @source_file = source_file
    end

    def name
      definition[:name]
    end

    def description
      definition[:description]
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

    def feature_category
      definition[:feature_category]
    end
  end
end
