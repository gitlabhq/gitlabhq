# frozen_string_literal: true

class MergeRequestsClosingIssues < ApplicationRecord
  belongs_to :merge_request
  belongs_to :issue

  validates :merge_request_id, uniqueness: { scope: :issue_id }, presence: true
  validates :issue_id, presence: true

  scope :with_issues, ->(ids) { where(issue_id: ids) }
  scope :with_merge_requests_enabled, -> do
    joins(:merge_request)
      .joins('INNER JOIN project_features ON merge_requests.target_project_id = project_features.project_id')
      .where('project_features.merge_requests_access_level >= :access', access: ProjectFeature::ENABLED)
  end

  scope :accessible_by, ->(user) do
    joins(:merge_request)
      .joins('INNER JOIN project_features ON merge_requests.target_project_id = project_features.project_id')
      .where('project_features.merge_requests_access_level >= :access OR EXISTS(:authorizations)',
             access: ProjectFeature::ENABLED,
             authorizations: user.authorizations_for_projects(min_access_level: Gitlab::Access::REPORTER, related_project_column: "merge_requests.target_project_id")
            )
  end

  class << self
    def count_for_collection(ids, current_user)
      closing_merge_requests(ids, current_user).group(:issue_id).pluck('issue_id', 'COUNT(*) as count')
    end

    def count_for_issue(id, current_user)
      closing_merge_requests(id, current_user).count
    end

    private

    def closing_merge_requests(ids, current_user)
      return with_issues(ids) if current_user&.admin?
      return with_issues(ids).with_merge_requests_enabled if current_user.blank?

      with_issues(ids).accessible_by(current_user)
    end
  end
end
