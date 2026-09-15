# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        module Views
          class SchemaResolution < Base
            SCHEMA_HEADERS = %w[SCHEMA OWNER CURRENT].freeze
            FACT_LABEL_WIDTH = 'Current user:'.length

            def self.title
              'Search path'
            end

            private

            def print_database(database_name, payload)
              print_status(database_name, payload)
              print_facts(payload)
              print_findings(payload[:findings] || [])
              print_schemas(payload[:schemas] || [])
            end

            def print_facts(payload)
              printer.key_value('Current user', payload[:current_user], label_width: FACT_LABEL_WIDTH)
              printer.key_value('Search path', payload[:search_path], label_width: FACT_LABEL_WIDTH)
              printer.blank_line
            end

            def print_schemas(schemas)
              printer.subheading('Schemas')
              printer.table(SCHEMA_HEADERS, schemas.map { |schema| schema_row(schema) })
            end

            # Blank cell, not "no": the web card renders the badge only when current.
            def schema_row(schema)
              [schema[:name], schema[:owner], schema[:current] ? 'yes' : '']
            end
          end
        end
      end
    end
  end
end
