# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        module Views
          class Base
            EXCEPTION_HINT = 'The underlying exception was sent to the exception tracker; ' \
              'see the GitLab application logs for the cause.'

            def self.title
              raise Gitlab::AbstractMethodError
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

            def print_database(_database_name, _payload)
              raise Gitlab::AbstractMethodError
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

            # In the order the check supplied.
            def print_findings(findings)
              return if findings.empty?

              findings.each { |finding| printer.finding(finding[:severity], finding[:message]) }

              printer.blank_line
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
