# frozen_string_literal: true

module Gitlab
  module JiraImport
    class MetadataCollector
      attr_accessor :jira_issue, :metadata

      def initialize(jira_issue)
        @jira_issue = jira_issue
        @metadata = []
      end

      def execute
        add_field(%w(issuetype name), 'Issue type')
        add_field(%w(priority name), 'Priority')
        add_labels
        add_field('environment', 'Environment')
        add_field('duedate', 'Due date')
        add_parent
        add_versions

        return if metadata.empty?

        metadata.join("\n").prepend("\n\n---\n\n**Issue metadata**\n\n")
      end

      private

      def add_field(keys, field_label)
        value = fields.dig(*keys)
        return if value.blank?

        metadata << "- #{field_label}: #{value}"
      end

      def add_labels
        return if fields['labels'].blank?

        metadata << "- Labels: #{fields['labels'].join(', ')}"
      end

      def add_parent
        parent_issue_key = fields.dig('parent', 'key')
        return if parent_issue_key.blank?

        metadata << "- Parent issue: [#{parent_issue_key}] #{fields['parent']['fields']['summary']}"
      end

      def add_versions
        return if fields['fixVersions'].blank?

        metadata << "- Fix versions: #{fields['fixVersions'].map { |version| version['name'] }.join(', ')}"
      end

      def fields
        jira_issue.fields
      end
    end
  end
end
