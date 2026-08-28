# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        module Views
          class AutovacuumSettings < Base
            SETTING_HEADERS = %w[SETTING VALUE].freeze
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
            end

            def print_settings(settings)
              return printer.detail(EMPTY) if settings.empty?

              printer.subheading('Effective settings')
              printer.table(SETTING_HEADERS, settings.map { |name, entry| [name, display_value(entry)] })
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
