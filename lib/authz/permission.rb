# frozen_string_literal: true

module Authz
  class Permission
    class << self
      def all
        @permissions ||= load_definitions
      end

      def get(name)
        all[name]
      end

      private

      def load_definitions
        permission_defs = {}

        Dir.glob(permission_path).each do |file|
          definition = load_from_file(file)
          permission_defs[definition[:name].to_sym] = new(definition)
        end

        permission_defs
      end

      def load_from_file(path)
        definition = File.read(path)
        definition = YAML.safe_load(definition)
        definition.deep_symbolize_keys!
        definition
      end

      def permission_path
        Rails.root.join("config/authz/permissions/**/*.yml")
      end
    end

    def initialize(definition)
      @definition = definition
    end

    def name
      definition[:name]
    end

    def description
      definition[:description]
    end

    def scopes
      definition[:scopes] || []
    end

    def feature_category
      definition[:feature_category]
    end

    private

    attr_reader :definition
  end
end
