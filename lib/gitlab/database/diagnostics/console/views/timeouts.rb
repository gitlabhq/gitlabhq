# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        module Views
          class Timeouts < Base
            SETTING_HEADERS = ['SETTING', 'SESSION', 'CLUSTER DEFAULT', 'SOURCE'].freeze
            OVERRIDE_HEADERS = %w[ROLE DATABASE SETTING VALUE].freeze

            OVERRIDES_SUBHEADING = 'Role and database defaults'

            UNLIMITED_LABEL = 'unlimited'
            ALL_LABEL = '(all)'

            def self.title
              'Timeouts'
            end

            private

            def print_database(database_name, payload)
              timeouts = payload[:timeouts] || {}

              print_status(database_name, timeouts)
              print_findings(timeouts[:findings] || [])
              print_settings(timeouts[:settings] || {})
              print_overrides(timeouts[:overrides] || [])
            end

            def print_settings(settings)
              return if settings.empty?

              printer.subheading(SETTINGS_SUBHEADING)
              printer.table(SETTING_HEADERS, settings.map { |name, setting| setting_row(name, setting) })
            end

            # Absent whenever no role or database carries a timeout of its own, which
            # is the common case.
            def print_overrides(overrides)
              return if overrides.empty?

              printer.blank_line
              printer.subheading(OVERRIDES_SUBHEADING)
              printer.table(OVERRIDE_HEADERS, overrides.map { |override| override_row(override) })
            end

            def setting_row(name, setting)
              [
                name,
                duration(setting[:value], setting[:unit]),
                duration(setting[:default_value], setting[:unit]),
                source(setting)
              ]
            end

            def override_row(override)
              [
                override[:role_name] || ALL_LABEL,
                override[:database_name] || ALL_LABEL,
                override[:name],
                override[:value]
              ]
            end

            def duration(value, unit)
              return UNLIMITED_LABEL if value == Checks::Timeouts::UNLIMITED

              [value, unit].compact_blank.join(' ')
            end

            def source(setting)
              return setting[:source] if setting[:source_location].blank?

              "#{setting[:source]} (#{setting[:source_location]})"
            end
          end
        end
      end
    end
  end
end
