# frozen_string_literal: true

class ServiceDeskSetting < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  belongs_to :project
  validates :project_id, presence: true
  validate :valid_issue_template
  validate :valid_project_key
  validates :outgoing_name, length: { maximum: 255 }, allow_blank: true
  validates :project_key,
            length: { maximum: 255 },
            allow_blank: true,
            format: { with: /\A[a-z0-9_]+\z/, message: -> (setting, data) { _("can contain only lowercase letters, digits, and '_'.") } }

  scope :with_project_key, ->(key) { where(project_key: key) }

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

  def valid_project_key
    if projects_with_same_slug_and_key_exists?
      errors.add(:project_key, 'already in use for another service desk address.')
    end
  end

  private

  def projects_with_same_slug_and_key_exists?
    return false unless project_key

    settings = self.class.with_project_key(project_key).preload(:project)
    project_slug = self.project.full_path_slug

    settings.any? do |setting|
      setting.project.full_path_slug == project_slug
    end
  end
end
