class MergeRequestBasicEntity < Grape::Entity
  expose :merge_status
  expose :merge_error
  expose :state
  expose :source_branch_exists?, as: :source_branch_exists
  expose :time_estimate
  expose :total_time_spent
  expose :human_time_estimate
  expose :human_total_time_spent
  expose :rebase_in_progress?, as: :rebase_in_progress
end
