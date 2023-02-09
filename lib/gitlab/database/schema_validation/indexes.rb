# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class Indexes
        def initialize(structure_sql, database)
          @structure_sql = structure_sql
          @database = database
        end

        def missing_indexes
          structure_sql.indexes.map(&:name) - database.indexes.map(&:name)
        end

        def extra_indexes
          database.indexes.map(&:name) - structure_sql.indexes.map(&:name)
        end

        def wrong_indexes
          structure_sql.indexes.filter_map do |structure_sql_index|
            database_index = database.fetch_index_by_name(structure_sql_index.name)

            next if database_index.nil?
            next if database_index.statement == structure_sql_index.statement

            structure_sql_index.name
          end
        end

        private

        attr_reader :structure_sql, :database
      end
    end
  end
end
