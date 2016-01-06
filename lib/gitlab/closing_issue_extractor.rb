module Gitlab
  class ClosingIssueExtractor
    ISSUE_CLOSING_REGEX = begin
      link_pattern = URI.regexp(%w(http https))

      pattern = Gitlab.config.gitlab.issue_closing_pattern
      pattern = pattern.sub('%{issue_ref}', "(?:(?:#{link_pattern})|(?:#{Issue.reference_pattern}))")
      Regexp.new(pattern).freeze
    end

    def initialize(project, current_user = nil)
      @extractor = Gitlab::ReferenceExtractor.new(project, current_user)
    end

    def closed_by_message(message)
      return [] if message.nil?

      closing_statements = []
      message.scan(ISSUE_CLOSING_REGEX) do
        closing_statements << Regexp.last_match[0]
      end

      @extractor.analyze(closing_statements.join(" "))

      @extractor.issues
    end
  end
end
