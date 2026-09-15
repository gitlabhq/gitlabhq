# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Console
        OK = 'OK'
        UNAVAILABLE = 'unavailable'
        FAILED = 'failed'

        VIEWS = {
          'search_path' => Views::SchemaResolution,
          'autovacuum_settings' => Views::AutovacuumSettings
        }.freeze

        UnknownCheckError = Class.new(ArgumentError)

        # Blank check_names runs every registered check.
        def self.run(database_names:, check_names: nil, output: $stdout)
          Runner.new(database_names: database_names, views: select_views(check_names), output: output).run
        end

        def self.select_views(check_names)
          names = Array(check_names).map(&:to_s).uniq
          return VIEWS.values if names.empty?

          unknown = names - VIEWS.keys
          if unknown.any?
            raise UnknownCheckError, "Unknown check(s): #{unknown.join(', ')}. Valid: #{VIEWS.keys.join(', ')}."
          end

          VIEWS.fetch_values(*names)
        end
        private_class_method :select_views

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
