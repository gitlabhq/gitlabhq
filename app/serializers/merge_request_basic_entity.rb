# frozen_string_literal: true

class MergeRequestBasicEntity < IssuableSidebarEntity
  expose :assignee_id
  expose :merge_status
  expose :merge_error
  expose :state
  expose :source_branch_exists?, as: :source_branch_exists
  expose :rebase_in_progress?, as: :rebase_in_progress
  expose :milestone, using: API::Entities::Milestone
  expose :labels, using: LabelEntity
  expose :assignee, using: API::Entities::UserBasic
  expose :task_status, :task_status_short
end
