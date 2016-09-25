class EnvironmentPolicy < BasePolicy
  def rules
    delegate! @subject.project
  end
end
