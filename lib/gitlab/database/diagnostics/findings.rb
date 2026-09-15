# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Findings
        ERROR = 'error'
        WARNING = 'warning'

        # Severity strings are mirrored by SEVERITY_VARIANTS in db_information_card.vue.
        SEVERITY_ORDER = { ERROR => 0, WARNING => 1 }.freeze

        # Unknown severities last. sort_by is unstable, hence the index tiebreaker.
        def self.sort(findings)
          findings
            .each_with_index
            .sort_by { |finding, index| [rank(finding[:severity]), index] }
            .map(&:first)
        end

        def self.counts(findings)
          findings.pluck(:severity).tally
        end

        def self.worst(severities)
          SEVERITY_ORDER.keys.find { |severity| severities.include?(severity) }
        end

        def self.rank(severity)
          SEVERITY_ORDER.fetch(severity, Float::INFINITY)
        end
      end
    end
  end
end
