# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        OK = 'OK'
        UNAVAILABLE = 'unavailable'
        FAILED = 'failed'

        VIEWS = [Views::SchemaResolution].freeze

        def self.run(database_names:, output: $stdout)
          Runner.new(database_names: database_names, output: output).run
        end

        # nil when there is nothing to report, so callers pick their own wording.
        def self.summarize(counts)
          return if counts.empty?

          counts
            .sort_by { |severity, _| Findings.rank(severity) }
            .map { |severity, count| "#{count} #{severity.pluralize(count)}" }
            .join(', ')
        end

        def self.merge_counts(counts_list)
          counts_list.reduce({}) { |merged, counts| merged.merge(counts) { |_, a, b| a + b } }
        end
      end
    end
  end
end
