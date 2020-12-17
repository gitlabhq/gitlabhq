# frozen_string_literal: true

class SentryIssue < ApplicationRecord
  include Importable

  belongs_to :issue

  validates :issue, uniqueness: true
  validates :issue, presence: true, unless: :importing?
  validates :sentry_issue_identifier, presence: true
  validate :ensure_sentry_issue_identifier_is_unique_per_project

  after_create_commit :enqueue_sentry_sync_job

  def self.for_project_and_identifier(project, identifier)
    joins(:issue)
      .where(issues: { project_id: project.id })
      .where(sentry_issue_identifier: identifier)
      .order('issues.created_at').last
  end

  def ensure_sentry_issue_identifier_is_unique_per_project
    if issue && self.class.for_project_and_identifier(issue.project, sentry_issue_identifier).present?
      # Custom message because field is hidden
      errors.add(:_, _('is already associated to a GitLab Issue. New issue will not be associated.'))
    end
  end

  def enqueue_sentry_sync_job
    ErrorTrackingIssueLinkWorker.perform_async(issue.id)
  end
end
