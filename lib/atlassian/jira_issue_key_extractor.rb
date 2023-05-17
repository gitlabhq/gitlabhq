# frozen_string_literal: true

module Atlassian
  class JiraIssueKeyExtractor
    def self.has_keys?(...)
      new(...).issue_keys.any?
    end

    def initialize(*text, custom_regex: nil)
      @text = text.join(' ')
      @match_regex = custom_regex || Gitlab::Regex.jira_issue_key_regex
    end

    def issue_keys
      @text.scan(@match_regex).flatten.uniq
    end
  end
end
