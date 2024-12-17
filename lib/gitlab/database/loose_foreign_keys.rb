# frozen_string_literal: true

module Gitlab
  module Database
    module LooseForeignKeys
      def self.definitions_by_table
        @definitions_by_table ||= definitions.group_by(&:to_table).with_indifferent_access.freeze
      end

      def self.definitions
        @definitions ||= loose_foreign_keys_yaml.flat_map do |child_table_name, configs|
          configs.map { |config| build_definition(child_table_name, config) }
        end.freeze
      end

      def self.build_definition(child_table_name, config)
        parent_table_name = config.fetch('table')

        conditions = config['conditions']&.map { |hash| hash.transform_keys(&:to_sym) }

        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
          child_table_name,
          parent_table_name,
          {
            column: config.fetch('column'),
            on_delete: config.fetch('on_delete').to_sym,
            gitlab_schema: GitlabSchema.table_schema!(child_table_name),
            target_column: config['target_column'],
            target_value: config['target_value'],
            conditions: conditions
          }
        )
      end

      def self.loose_foreign_keys_yaml
        @loose_foreign_keys_yaml ||= YAML.load_file(self.loose_foreign_keys_yaml_path)
      end

      def self.loose_foreign_keys_yaml_path
        @loose_foreign_keys_yaml_path ||= Rails.root.join('config/gitlab_loose_foreign_keys.yml')
      end

      private_class_method :build_definition
      private_class_method :loose_foreign_keys_yaml
    end
  end
end
