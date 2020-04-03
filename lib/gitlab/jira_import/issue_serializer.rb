# frozen_string_literal: true

module Gitlab
  module JiraImport
    class IssueSerializer
      attr_reader :jira_issue, :project, :params, :formatter
      attr_accessor :metadata

      def initialize(project, jira_issue, params = {})
        @jira_issue = jira_issue
        @project = project
        @params = params
        @formatter = Gitlab::ImportFormatter.new
        @metadata = []
      end

      def execute
        {
          iid: params[:iid],
          project_id: project.id,
          description: description,
          title: title,
          state_id: map_status(jira_issue.status.statusCategory),
          updated_at: jira_issue.updated,
          created_at: jira_issue.created,
          author_id: project.creator_id # TODO: map actual author: https://gitlab.com/gitlab-org/gitlab/-/issues/210580
        }
      end

      private

      def title
        "[#{jira_issue.key}] #{jira_issue.summary}"
      end

      def description
        body = []
        body << formatter.author_line(jira_issue.reporter.displayName)
        body << formatter.assignee_line(jira_issue.assignee.displayName) if jira_issue.assignee
        body << jira_issue.description
        body << add_metadata

        body.join
      end

      def map_status(jira_status_category)
        case jira_status_category["key"].downcase
        when 'done'
          Issuable::STATE_ID_MAP[:closed]
        else
          Issuable::STATE_ID_MAP[:opened]
        end
      end

      def add_metadata
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
