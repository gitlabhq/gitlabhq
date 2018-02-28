class MergeRequestBasicEntity < IssuableSidebarEntity
  expose :assignee_id
  expose :merge_status
  expose :merge_error
  expose :state
  expose :source_branch_exists?, as: :source_branch_exists
end
