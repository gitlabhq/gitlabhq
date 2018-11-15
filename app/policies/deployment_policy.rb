# frozen_string_literal: true

class DeploymentPolicy < BasePolicy
  delegate { @subject.project }

  condition(:can_retry_deployable) do
    can?(:update_build, @subject.deployable)
  end

  rule { ~can_retry_deployable }.policy do
    prevent :create_deployment
    prevent :update_deployment
  end
end
