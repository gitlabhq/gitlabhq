# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        module Views
          class SchemaResolution
            SCHEMA_HEADERS = %w[SCHEMA OWNER CURRENT].freeze
            FACT_LABEL_WIDTH = 'Current user:'.length

            # collect_for_database swallows the exception, so the console has no cause to show.
            EXCEPTION_HINT = 'The underlying exception was sent to the exception tracker; ' \
              'see the GitLab application logs for the cause.'

            def self.title
              'Search path'
            end

            def initialize(databases:, printer:)
              @databases = databases
              @printer = printer
              @counts = {}
            end

            # Returns the per-severity counts it displayed.
            def run
              printer.section(self.class.title)

              databases.each do |database_name, payload|
                if payload[:error]
                  print_unavailable(database_name, payload)
                else
                  print_database(database_name, payload)
                end

                printer.blank_line
                printer.flush
              end

              counts
            end

            private

            attr_reader :databases, :printer, :counts

            def print_database(database_name, payload)
              print_status(database_name, payload)
              print_facts(payload)
              print_findings(payload[:findings] || [])
              print_schemas(payload[:schemas] || [])
            end

            def print_unavailable(database_name, payload)
              add_counts(Findings::ERROR => 1)

              printer.status(database_name, UNAVAILABLE, Findings::ERROR)
              printer.detail(payload[:error])
              printer.detail(EXCEPTION_HINT)
            end

            def print_status(label, payload)
              severity_counts = payload[:counts] || {}
              add_counts(severity_counts)

              printer.status(label, Console.summarize(severity_counts) || OK, payload[:severity])
            end

            def print_facts(payload)
              printer.key_value('Current user', payload[:current_user], label_width: FACT_LABEL_WIDTH)
              printer.key_value('Search path', payload[:search_path], label_width: FACT_LABEL_WIDTH)
              printer.blank_line
            end

            # In the order the check supplied.
            def print_findings(findings)
              return if findings.empty?

              findings.each { |finding| printer.finding(finding[:severity], finding[:message]) }

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

            def add_counts(severity_counts)
              @counts = Console.merge_counts([counts, severity_counts])
            end
          end
        end
      end
    end
  end
end
