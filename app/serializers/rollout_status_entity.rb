class RolloutStatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :instances
  expose :completion
  expose :valid?, as: :valid

  expose :is_completed do |rollout_status|
    rollout_status.complete?
  end
end
