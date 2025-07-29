# frozen_string_literal: true

module Gitlab
  module WorkItems
    class TimeTrackingExtractor
      TIME_TRACKING_REGEX = /@(\d+(?:mo|[dhms])(?:\d+(?:mo|[dhms]))*)/

      # Expose the time tracking regex pattern to be used in cross-reference detection
      def self.reference_pattern
        TIME_TRACKING_REGEX
      end

      def initialize(project, current_user)
        @project = project
        @current_user = current_user
        @extractor = Gitlab::ReferenceExtractor.new(project, current_user)
      end

      def extract_time_spent(message)
        return {} if message.blank?

        time_spent = find_time_spent(message)
        return {} unless time_spent

        extractor.analyze(message)
        referenced_issues = (extractor.issues + extractor.work_items).uniq(&:id)

        referenced_issues.index_with do |_issue|
          time_spent
        end
      end

      private

      attr_reader :project, :current_user, :extractor

      def find_time_spent(message)
        matches = message.scan(TIME_TRACKING_REGEX)
        return if matches.empty?

        matches.each do |match|
          time_string = match[0]
          time_spent = Gitlab::TimeTrackingFormatter.parse(time_string)
          return time_spent if time_spent
        end

        nil
      end
    end
  end
end
