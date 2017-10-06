class RolloutStatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :status, as: :status

  expose :instances, if: -> (rollout_status, _) { rollout_status.found? }
  expose :completion, if: -> (rollout_status, _) { rollout_status.found? }
  expose :complete?, as: :is_completed, if: -> (rollout_status, _) { rollout_status.found? }
end
