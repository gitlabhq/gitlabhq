class MergeRequestBasicEntity < IssuableSidebarEntity
  expose :assignee_id
  expose :merge_status
  expose :merge_error
  expose :state
  expose :source_branch_exists?, as: :source_branch_exists
<<<<<<< HEAD
  expose :rebase_in_progress?, as: :rebase_in_progress
=======
>>>>>>> 6306e797acca358c79c120e5b12c29a5ec604571
end
