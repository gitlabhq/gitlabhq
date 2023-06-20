# frozen_string_literal: true

module Gitlab
  module Database
    GitlabSchemaInfo = Struct.new(
      :name,
      :description,
      :allow_cross_joins,
      :allow_cross_transactions,
      :allow_cross_foreign_keys,
      :file_path,
      keyword_init: true
    ) do
      def initialize(*)
        super
        self.name = name.to_sym
        self.allow_cross_joins = allow_cross_joins&.map(&:to_sym)&.freeze
        self.allow_cross_transactions = allow_cross_transactions&.map(&:to_sym)&.freeze
        self.allow_cross_foreign_keys = allow_cross_foreign_keys&.map(&:to_sym)&.freeze
      end

      def self.load_file(yaml_file)
        content = YAML.load_file(yaml_file)
        new(**content.deep_symbolize_keys.merge(file_path: yaml_file))
      end
    end
  end
end
