# frozen_string_literal: true

class DeploymentPolicy < BasePolicy
  delegate { @subject.project }

  condition(:can_retry_deployable) do
    can?(:update_build, @subject.deployable)
  end

  condition(:has_deployable) do
    @subject.deployable.present?
  end

  condition(:can_update_deployment) do
    can?(:update_deployment, @subject.environment)
  end

  rule { has_deployable & ~can_retry_deployable }.policy do
    prevent :create_deployment
    prevent :update_deployment
  end

  rule { ~can_update_deployment }.policy do
    prevent :update_deployment
  end
end

DeploymentPolicy.prepend_mod_with('DeploymentPolicy')
