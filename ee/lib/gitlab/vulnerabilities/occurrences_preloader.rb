# frozen_string_literal: true

module Gitlab
  # Preloading of Vulnerabilities Occurrences.
  #
  # This class can be used to efficiently preload the feedback of a given list of
  # vulnerabilities (occurrences).
  module Vulnerabilities
    class OccurrencesPreloader
      def preload(occurrences)
        occurrences.each(&:issue_feedback)
        occurrences.each(&:dismissal_feedback)
      end
    end
  end
end
