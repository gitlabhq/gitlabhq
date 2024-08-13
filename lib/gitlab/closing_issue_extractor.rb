# frozen_string_literal: true

module Gitlab
  class ClosingIssueExtractor
    # Rubular: https://rubular.com/r/PqADDyNVtBUpXl
    # Note that it's not possible to use Gitlab::UntrustedRegexp for LINK_PATTERN,
    # as `(?<!` is unsupported in `re2`, see https://github.com/google/re2/wiki/Syntax
    HTTP_LINK_PATTERN = %r{((http|https)://[^\s>]{1,300})(?<!\?|!|\.|,|:)}

    ISSUE_CLOSING_REGEX = begin
      link_pattern = HTTP_LINK_PATTERN

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

      closing_statements = []
      message.scan(ISSUE_CLOSING_REGEX) do
        closing_statements << Regexp.last_match[0]
      end

      @extractor.analyze(closing_statements.join(" "))
      relevant_records = (@extractor.issues + @extractor.work_items).uniq(&:id)

      relevant_records.reject do |issue|
        @extractor.project.forked_from?(issue.project)
      end
    end
  end
end
