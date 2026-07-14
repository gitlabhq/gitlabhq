# frozen_string_literal: true

class MergeRequestsClosingIssues < ApplicationRecord
  include BulkInsertSafe

  enum :link_type, { closes: 0, mentioned: 1, related: 2 }, prefix: true

  belongs_to :merge_request
  belongs_to :issue
  belongs_to :project

  validates :merge_request_id, uniqueness: { scope: [:issue_id, :link_type] }, presence: true
  validates :issue_id, presence: true
  validate :from_mr_description_only_for_closes

  scope :with_opened_merge_request, -> { joins(:merge_request).merge(MergeRequest.with_state(:opened)) }
  scope :from_mr_description, -> { where(from_mr_description: true) }
  scope :user_created, -> { where(from_mr_description: false) }
  scope :with_issues, ->(ids) { where(issue_id: ids) }
  scope :by_link_types, ->(types) { where(link_type: types) }
  scope :with_merge_requests_enabled, -> do
    joins(:merge_request)
      .joins('INNER JOIN project_features ON merge_requests.target_project_id = project_features.project_id')
      .where('project_features.merge_requests_access_level >= :access', access: ProjectFeature::ENABLED)
  end

  scope :accessible_by, ->(user) do
    joins(:merge_request)
      .joins('INNER JOIN project_features ON merge_requests.target_project_id = project_features.project_id')
      .where(
        'project_features.merge_requests_access_level >= :access OR EXISTS(:authorizations)',
        access: ProjectFeature::ENABLED,
        authorizations: user.authorizations_for_projects(min_access_level: Gitlab::Access::REPORTER, related_project_column: "merge_requests.target_project_id")
      )
  end

  class << self
    def preload_merge_request_for_authorization
      preload(merge_request: [:target_project, :author])
    end

    def preload_issue
      preload(:issue)
    end

    def count_for_collection(ids, current_user)
      closing_merge_requests(ids, current_user).group(:issue_id).pluck('issue_id', Arel.sql('COUNT(*) as count'))
    end

    def count_for_issue(id, current_user)
      closing_merge_requests(id, current_user).count
    end

    private

    def closing_merge_requests(ids, current_user)
      base = with_issues(ids).link_type_closes
      return base if current_user&.admin?
      return base.with_merge_requests_enabled if current_user.blank?

      base.accessible_by(current_user)
    end
  end

  private

  def from_mr_description_only_for_closes
    return unless from_mr_description && !link_type_closes?

    errors.add(:from_mr_description, 'can only be true when link_type is closes')
  end
end
