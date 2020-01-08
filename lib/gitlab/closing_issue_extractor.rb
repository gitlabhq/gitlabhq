# frozen_string_literal: true

module Gitlab
  class ClosingIssueExtractor
    ISSUE_CLOSING_REGEX = begin
      link_pattern = Banzai::Filter::AutolinkFilter::LINK_PATTERN

      pattern = Gitlab.config.gitlab.issue_closing_pattern
      pattern = pattern.sub('%{issue_ref}', "(?:(?:#{link_pattern})|(?:#{Issue.reference_pattern}))")
      Regexp.new(pattern).freeze
    end

    def initialize(project, current_user = nil)
      @project = project
      @extractor = Gitlab::ReferenceExtractor.new(project, current_user)
    end

    def closed_by_message(message)
      return [] if message.nil?
      return [] unless @project.autoclose_referenced_issues

      closing_statements = []
      message.scan(ISSUE_CLOSING_REGEX) do
        closing_statements << Regexp.last_match[0]
      end

      @extractor.analyze(closing_statements.join(" "))

      @extractor.issues.reject do |issue|
        # Don't extract issues from the project this project was forked from
        @extractor.project.forked_from?(issue.project)
      end
    end
  end
end
