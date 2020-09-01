# frozen_string_literal: true

module Atlassian
  class JiraIssueKeyExtractor
    def self.has_keys?(*text)
      new(*text).issue_keys.any?
    end

    def initialize(*text)
      @text = text.join(' ')
    end

    def issue_keys
      @text.scan(Gitlab::Regex.jira_issue_key_regex).uniq
    end
  end
end
