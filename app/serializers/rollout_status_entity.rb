class RolloutStatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :instances
  expose :completion

  expose :is_completed do |rollout_status|
    rollout_status.complete?
  end
end
