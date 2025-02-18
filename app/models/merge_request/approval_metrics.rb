# frozen_string_literal: true

class MergeRequest::ApprovalMetrics < ApplicationRecord # rubocop:disable Style/ClassAndModuleChildren, Gitlab/BoundedContexts -- Same as the rest of the models
  belongs_to :merge_request, optional: false
  belongs_to :target_project, class_name: 'Project', inverse_of: :merge_requests, optional: false

  validates :last_approved_at, presence: true

  def self.refresh_last_approved_at(merge_request:, last_approved_at:)
    attributes = {
      merge_request_id: merge_request.id,
      target_project_id: merge_request.target_project_id,
      last_approved_at: last_approved_at
    }

    upsert(
      attributes,
      unique_by: :merge_request_id,
      on_duplicate: Arel.sql(<<~SQL.squish)
        last_approved_at = GREATEST(excluded.last_approved_at, merge_request_approval_metrics.last_approved_at)
      SQL
    )
  end
end
