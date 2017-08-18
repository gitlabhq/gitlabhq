class DeploymentPolicy < BasePolicy
  delegate { @subject.project }
end
