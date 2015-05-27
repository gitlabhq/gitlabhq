module Gitlab
  class ClosingIssueExtractor
    ISSUE_CLOSING_REGEX = Regexp.new(Gitlab.config.gitlab.issue_closing_pattern)

    def initialize(project, current_user = nil)
      @extractor = Gitlab::ReferenceExtractor.new(project, current_user)
    end

    def closed_by_message(message)
      return [] if message.nil?

      closing_statements = message.scan(ISSUE_CLOSING_REGEX).
        map { |ref| ref[0] }.join(" ")

      @extractor.analyze(closing_statements)

      @extractor.issues
    end
  end
end
