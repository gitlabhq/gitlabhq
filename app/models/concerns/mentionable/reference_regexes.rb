module Mentionable
  module ReferenceRegexes
    def self.reference_pattern(link_patterns, issue_pattern)
      Regexp.union(link_patterns,
                   issue_pattern,
                   Epic.reference_pattern,
                   Commit.reference_pattern,
                   MergeRequest.reference_pattern)
    end

    DEFAULT_PATTERN = begin
      issue_pattern = Issue.reference_pattern
      link_patterns = Regexp.union([Issue, Commit, MergeRequest, Epic].map(&:link_reference_pattern))
      reference_pattern(link_patterns, issue_pattern)
    end

    EXTERNAL_PATTERN = begin
      issue_pattern = IssueTrackerService.reference_pattern
      link_patterns = URI.regexp(%w(http https))
      reference_pattern(link_patterns, issue_pattern)
    end
  end
end
