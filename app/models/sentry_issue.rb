# frozen_string_literal: true

class SentryIssue < ApplicationRecord
  belongs_to :issue

  validates :issue, uniqueness: true, presence: true
  validates :sentry_issue_identifier, presence: true

  def self.for_project_and_identifier(project, identifier)
    joins(:issue)
      .where(issues: { project_id: project.id })
      .find_by_sentry_issue_identifier(identifier)
  end
end
