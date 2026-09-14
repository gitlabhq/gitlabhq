# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        module Views
          class AutovacuumSettings < Base
            SETTING_HEADERS = %w[SETTING VALUE].freeze
            OVERRIDE_HEADERS = %w[TABLE SIZE ROWS OVERRIDES].freeze
            RISK_HEADERS = %w[TABLE SIZE ROWS].freeze
            EMPTY = 'No autovacuum settings could be read.'

            def self.title
              'Autovacuum settings'
            end

            private

            def print_database(database_name, payload)
              config = payload[:autovacuum_config] || {}

              print_status(database_name, config)
              print_findings(config[:findings] || [])
              print_settings(config[:settings] || {})
              print_overrides(config[:table_overrides] || [])
              print_risks(config[:scale_factor_risks] || [])
            end

            def print_settings(settings)
              return printer.detail(EMPTY) if settings.empty?

              printer.subheading('Effective settings')
              printer.table(SETTING_HEADERS, settings.map { |name, entry| [name, display_value(entry)] })
            end

            def print_overrides(tables)
              return if tables.empty?

              printer.blank_line
              printer.subheading('Per-table overrides')
              printer.table(OVERRIDE_HEADERS, tables.map do |table|
                [
                  table_label(table),
                  size_and_rows(table),
                  table[:overrides].map { |name, value| "#{name}=#{value}" }.join(', ')
                ].flatten
              end)
            end

            def print_risks(tables)
              return if tables.empty?

              printer.blank_line
              printer.subheading('Scale factor risk: large tables with a high scale factor in effect')
              printer.table(RISK_HEADERS, tables.map { |table| [qualified_name(table), size_and_rows(table)].flatten })
            end

            def table_label(table)
              label = qualified_name(table)
              table[:autovacuum_disabled] ? "#{label} (autovacuum disabled)" : label
            end

            def qualified_name(table)
              "#{table[:schema_name]}.#{table[:table_name]}"
            end

            def size_and_rows(table)
              [
                ActiveSupport::NumberHelper.number_to_human_size(table[:total_bytes]),
                "~#{ActiveSupport::NumberHelper.number_to_delimited(table[:estimated_rows])}"
              ]
            end

            def display_value(entry)
              return "#{entry[:value]} (effective: #{entry[:effective_value]})" if entry[:effective_value]

              entry[:unit] && entry[:value] != '-1' ? "#{entry[:value]} #{entry[:unit]}" : entry[:value]
            end
          end
        end
      end
    end
  end
end
