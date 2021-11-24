# frozen_string_literal: true

module Gitlab
  module Database
    module LooseForeignKeys
      def self.definitions_by_table
        @definitions_by_table ||= definitions.group_by(&:from_table).with_indifferent_access.freeze
      end

      def self.definitions
        @definitions ||= loose_foreign_keys_yaml.flat_map do |parent_table_name, configs|
          configs.map { |config| build_definition(parent_table_name, config) }
        end.freeze
      end

      def self.build_definition(parent_table_name, config)
        to_table = config.fetch('to_table')

        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
          parent_table_name,
          to_table,
          {
            column: config.fetch('column'),
            on_delete: config.fetch('on_delete').to_sym,
            gitlab_schema: GitlabSchema.table_schema(to_table)
          }
        )
      end

      def self.loose_foreign_keys_yaml
        @loose_foreign_keys_yaml ||= YAML.load_file(Rails.root.join('lib/gitlab/database/gitlab_loose_foreign_keys.yml'))
      end

      private_class_method :build_definition
      private_class_method :loose_foreign_keys_yaml
    end
  end
end
