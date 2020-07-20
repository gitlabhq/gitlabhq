# frozen_string_literal: true

class ServiceDeskSetting < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  belongs_to :project
  validates :project_id, presence: true
  validate :valid_issue_template
  validates :outgoing_name, length: { maximum: 255 }, allow_blank: true
  validates :project_key, length: { maximum: 255 }, allow_blank: true, format: { with: /\A[a-z0-9_]+\z/ }

  def issue_template_content
    strong_memoize(:issue_template_content) do
      next unless issue_template_key.present?

      Gitlab::Template::IssueTemplate.find(issue_template_key, project).content
    rescue ::Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
    end
  end

  def issue_template_missing?
    issue_template_key.present? && !issue_template_content.present?
  end

  def valid_issue_template
    if issue_template_missing?
      errors.add(:issue_template_key, 'is empty or does not exist')
    end
  end
end
