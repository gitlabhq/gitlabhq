# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/active_record/migration/migration_generator'

module Gitlab
  module ClickHouse
    module MaterializedView
      class ChangeGenerator < MigrationGenerator
        source_root File.expand_path('templates', __dir__)

        desc <<~DESC
          Generates a new ClickHouse migration where the inner query of the materialized view can be altered.

          Example:
            rails generate gitlab:click_house:materialized_view:change materialized_view_name
        DESC

        def create_migration_file
          prepare_template_assigns!
          super
        end

        private

        def template
          'change_materialized_view_migration.rb.template'
        end

        def file_name
          if number_of_rebuilds == 0
            "change_materialized_view_#{name}"
          else
            "change_materialized_view_#{name}_v#{number_of_rebuilds + 1}"
          end
        end

        def number_of_rebuilds
          @number_of_rebuilds ||= Dir[Rails.root.join(db_migrate_path, "*_change_materialized_view_#{name}*")].size
        end

        def prepare_template_assigns!
          @view_name = name
          @old_query = old_materialized_view_query(@view_name).split("\n")
        end

        def old_materialized_view_query(name)
          sql = <<~SQL
            SELECT formatQuery(create_table_query) AS statement
            FROM system.tables
            WHERE table = {view:String} AND database = {database:String}
            AND engine = 'MaterializedView'
            LIMIT 1
          SQL

          query = ::ClickHouse::Client::Query.new(
            raw_query: sql,
            placeholders: {
              view: name,
              database: connection.database_name
            }
          )

          row = connection.select(query).first
          raise "Couldn't find materialized view '#{name}'" if row.nil?

          # Grab the inner query of the materialized view definition
          row['statement'].sub(/\A.*?\bAS\b\s*/m, '')
        end

        def connection
          @connection ||= ::ClickHouse::Connection.new(:main)
        end
      end
    end
  end
end
