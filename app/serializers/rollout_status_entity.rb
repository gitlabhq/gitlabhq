# frozen_string_literal: true

class RolloutStatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :status, as: :status

  # To be removed in API v5
  expose :has_legacy_app_label do |_rollout_status|
    false
  end

  expose :instances, if: ->(rollout_status, _) { rollout_status.found? }
  expose :completion, if: ->(rollout_status, _) { rollout_status.found? }
  expose :complete?, as: :is_completed, if: ->(rollout_status, _) { rollout_status.found? }
  expose :canary_ingress, using: RolloutStatuses::IngressEntity, expose_nil: false,
    if: ->(rollout_status, _) { rollout_status.found? && rollout_status.canary_ingress_exists? }
end
