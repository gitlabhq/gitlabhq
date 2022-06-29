# frozen_string_literal: true

class MergeRequestBasicEntity < Grape::Entity
  expose :title
  expose :public_merge_status, as: :merge_status
  expose :merge_error
  expose :state
  expose :source_branch_exists?, as: :source_branch_exists
  expose :rebase_in_progress?, as: :rebase_in_progress
  expose :should_be_rebased?, as: :should_be_rebased
  expose :milestone, using: API::Entities::Milestone
  expose :labels, using: LabelEntity
  expose :assignees, using: API::Entities::UserBasic
  expose :reviewers, using: API::Entities::UserBasic
  expose :task_status, :task_status_short
  expose :lock_version, :lock_version
end
