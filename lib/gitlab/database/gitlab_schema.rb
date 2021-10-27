# frozen_string_literal: true

# This module gathers information about table to schema mapping
# to understand table affinity
module Gitlab
  module Database
    module GitlabSchema
      def self.table_schemas(tables)
        tables.map { |table| table_schema(table) }.to_set
      end

      def self.table_schema(name)
        # When undefined it's best to return a unique name so that we don't incorrectly assume that 2 undefined schemas belong on the same database
        tables_to_schema[name] || :"undefined_#{name}"
      end

      def self.tables_to_schema
        @tables_to_schema ||= YAML.load_file(Rails.root.join('lib/gitlab/database/gitlab_schemas.yml'))
      end
    end
  end
end
