# frozen_string_literal: true

require_relative 'title_linting'

module Gitlab
  module Danger
    class BaseLinter
      MIN_SUBJECT_WORDS_COUNT = 3
      MAX_LINE_LENGTH = 72

      attr_reader :commit, :problems

      def self.problems_mapping
        {
          subject_too_short: "The %s must contain at least #{MIN_SUBJECT_WORDS_COUNT} words",
          subject_too_long: "The %s may not be longer than #{MAX_LINE_LENGTH} characters",
          subject_starts_with_lowercase: "The %s must start with a capital letter",
          subject_ends_with_a_period: "The %s must not end with a period"
        }
      end

      def self.subject_description
        'commit subject'
      end

      def initialize(commit)
        @commit = commit
        @problems = {}
      end

      def failed?
        problems.any?
      end

      def add_problem(problem_key, *args)
        @problems[problem_key] = sprintf(self.class.problems_mapping[problem_key], *args)
      end

      def lint_subject
        if subject_too_short?
          add_problem(:subject_too_short, self.class.subject_description)
        end

        if subject_too_long?
          add_problem(:subject_too_long, self.class.subject_description)
        end

        if subject_starts_with_lowercase?
          add_problem(:subject_starts_with_lowercase, self.class.subject_description)
        end

        if subject_ends_with_a_period?
          add_problem(:subject_ends_with_a_period, self.class.subject_description)
        end

        self
      end

      private

      def subject
        TitleLinting.remove_draft_flag(message_parts[0])
      end

      def subject_too_short?
        subject.split(' ').length < MIN_SUBJECT_WORDS_COUNT
      end

      def subject_too_long?
        line_too_long?(subject)
      end

      def line_too_long?(line)
        line.length > MAX_LINE_LENGTH
      end

      def subject_starts_with_lowercase?
        return false if ('A'..'Z').cover?(subject[0])

        first_char = subject.sub(/\A(\[.+\]|\w+:)\s/, '')[0]
        first_char_downcased = first_char.downcase
        return true unless ('a'..'z').cover?(first_char_downcased)

        first_char.downcase == first_char
      end

      def subject_ends_with_a_period?
        subject.end_with?('.')
      end

      def message_parts
        @message_parts ||= commit.message.split("\n", 3)
      end
    end
  end
end
