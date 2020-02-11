# frozen_string_literal: true

module IncidentManagement
  class ProjectIncidentManagementSetting < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    belongs_to :project

    validate :issue_template_exists, if: :create_issue?

    def available_issue_templates
      Gitlab::Template::IssueTemplate.all(project)
    end

    def issue_template_content
      strong_memoize(:issue_template_content) do
        issue_template&.content if issue_template_key.present?
      end
    end

    private

    def issue_template_exists
      return unless issue_template_key.present?

      errors.add(:issue_template_key, 'not found') unless issue_template
    end

    def issue_template
      Gitlab::Template::IssueTemplate.find(issue_template_key, project)
    rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
    end
  end
end
