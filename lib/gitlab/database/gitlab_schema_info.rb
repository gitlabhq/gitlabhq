# frozen_string_literal: true

module Gitlab
  module Database
    GitlabSchemaInfo = Struct.new(
      :name,
      :description,
      :file_path,
      keyword_init: true
    ) do
      def initialize(*)
        super
        self.name = name.to_sym
      end

      def self.load_file(yaml_file)
        content = YAML.load_file(yaml_file)
        new(**content.deep_symbolize_keys.merge(file_path: yaml_file))
      end
    end
  end
end
