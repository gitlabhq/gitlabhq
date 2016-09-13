class IntegrationPolicy < BasePolicy
  def rules
    delegate! @subject.project
  end
end
