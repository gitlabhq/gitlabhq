module Gitlab
  module ClosingIssueExtractor
    ISSUE_CLOSING_REGEX = Regexp.new(Gitlab.config.gitlab.issue_closing_pattern)

    def self.closed_by_message_in_project(message, project)
      md = ISSUE_CLOSING_REGEX.match(message)
      if md
        extractor = Gitlab::ReferenceExtractor.new
        extractor.analyze(md[0])
        extractor.issues_for(project)
      else
        []
      end
    end
  end
end
