# frozen_string_literal: true

emoji_checker_path = File.expand_path('emoji_checker', __dir__)
defined?(Rails) ? require_dependency(emoji_checker_path) : require_relative(emoji_checker_path)

module Gitlab
  module Danger
    class CommitLinter
      MIN_SUBJECT_WORDS_COUNT = 3
      MAX_LINE_LENGTH = 72
      MAX_CHANGED_FILES_IN_COMMIT = 3
      MAX_CHANGED_LINES_IN_COMMIT = 30
      SHORT_REFERENCE_REGEX = %r{([\w\-\/]+)?(?<!`)(#|!|&|%)\d+(?<!`)}.freeze
      DEFAULT_SUBJECT_DESCRIPTION = 'commit subject'
      WIP_PREFIX = 'WIP: '
      PROBLEMS = {
        subject_too_short: "The %s must contain at least #{MIN_SUBJECT_WORDS_COUNT} words",
        subject_too_long: "The %s may not be longer than #{MAX_LINE_LENGTH} characters",
        subject_starts_with_lowercase: "The %s must start with a capital letter",
        subject_ends_with_a_period: "The %s must not end with a period",
        separator_missing: "The commit subject and body must be separated by a blank line",
        details_too_many_changes: "Commits that change #{MAX_CHANGED_LINES_IN_COMMIT} or more lines across " \
          "at least #{MAX_CHANGED_FILES_IN_COMMIT} files must describe these changes in the commit body",
        details_line_too_long: "The commit body should not contain more than #{MAX_LINE_LENGTH} characters per line",
        message_contains_text_emoji: "Avoid the use of Markdown Emoji such as `:+1:`. These add limited value " \
          "to the commit message, and are displayed as plain text outside of GitLab",
        message_contains_unicode_emoji: "Avoid the use of Unicode Emoji. These add no value to the commit " \
          "message, and may not be displayed properly everywhere",
        message_contains_short_reference: "Use full URLs instead of short references (`gitlab-org/gitlab#123` or " \
          "`!123`), as short references are displayed as plain text outside of GitLab"
      }.freeze

      attr_reader :commit, :problems

      def initialize(commit)
        @commit = commit
        @problems = {}
        @linted = false
      end

      def fixup?
        commit.message.start_with?('fixup!', 'squash!')
      end

      def suggestion?
        commit.message.start_with?('Apply suggestion to')
      end

      def merge?
        commit.message.start_with?('Merge branch')
      end

      def revert?
        commit.message.start_with?('Revert "')
      end

      def multi_line?
        !details.nil? && !details.empty?
      end

      def failed?
        problems.any?
      end

      def add_problem(problem_key, *args)
        @problems[problem_key] = sprintf(PROBLEMS[problem_key], *args)
      end

      def lint(subject_description = "commit subject")
        return self if @linted

        @linted = true
        lint_subject(subject_description)
        lint_separator
        lint_details
        lint_message

        self
      end

      def lint_subject(subject_description)
        if subject_too_short?
          add_problem(:subject_too_short, subject_description)
        end

        if subject_too_long?
          add_problem(:subject_too_long, subject_description)
        end

        if subject_starts_with_lowercase?
          add_problem(:subject_starts_with_lowercase, subject_description)
        end

        if subject_ends_with_a_period?
          add_problem(:subject_ends_with_a_period, subject_description)
        end

        self
      end

      private

      def lint_separator
        return self unless separator && !separator.empty?

        add_problem(:separator_missing)

        self
      end

      def lint_details
        if !multi_line? && many_changes?
          add_problem(:details_too_many_changes)
        end

        details&.each_line do |line|
          line_without_urls = line.strip.gsub(%r{https?://\S+}, '')

          # If the line includes a URL, we'll allow it to exceed MAX_LINE_LENGTH characters, but
          # only if the line _without_ the URL does not exceed this limit.
          next unless line_too_long?(line_without_urls)

          add_problem(:details_line_too_long)
          break
        end

        self
      end

      def lint_message
        if message_contains_text_emoji?
          add_problem(:message_contains_text_emoji)
        end

        if message_contains_unicode_emoji?
          add_problem(:message_contains_unicode_emoji)
        end

        if message_contains_short_reference?
          add_problem(:message_contains_short_reference)
        end

        self
      end

      def files_changed
        commit.diff_parent.stats[:total][:files]
      end

      def lines_changed
        commit.diff_parent.stats[:total][:lines]
      end

      def many_changes?
        files_changed > MAX_CHANGED_FILES_IN_COMMIT && lines_changed > MAX_CHANGED_LINES_IN_COMMIT
      end

      def subject
        message_parts[0].delete_prefix(WIP_PREFIX)
      end

      def separator
        message_parts[1]
      end

      def details
        message_parts[2]&.gsub(/^Signed-off-by.*$/, '')
      end

      def line_too_long?(line)
        line.length > MAX_LINE_LENGTH
      end

      def subject_too_short?
        subject.split(' ').length < MIN_SUBJECT_WORDS_COUNT
      end

      def subject_too_long?
        line_too_long?(subject)
      end

      def subject_starts_with_lowercase?
        first_char = subject.sub(/\A(\[.+\]|\w+:)\s/, '')[0]
        first_char_downcased = first_char.downcase
        return true unless ('a'..'z').cover?(first_char_downcased)

        first_char.downcase == first_char
      end

      def subject_ends_with_a_period?
        subject.end_with?('.')
      end

      def message_contains_text_emoji?
        emoji_checker.includes_text_emoji?(commit.message)
      end

      def message_contains_unicode_emoji?
        emoji_checker.includes_unicode_emoji?(commit.message)
      end

      def message_contains_short_reference?
        commit.message.match?(SHORT_REFERENCE_REGEX)
      end

      def emoji_checker
        @emoji_checker ||= Gitlab::Danger::EmojiChecker.new
      end

      def message_parts
        @message_parts ||= commit.message.split("\n", 3)
      end
    end
  end
end
