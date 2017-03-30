class MergeRequestBasicEntity < Grape::Entity
  expose :merge_status
  expose :state
  expose :source_branch_exists?, as: :source_branch_exists
end
