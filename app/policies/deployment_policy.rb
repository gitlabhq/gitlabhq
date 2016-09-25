class DeploymentPolicy < BasePolicy
  def rules
    delegate! @subject.project
  end
end
