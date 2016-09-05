class ExternalIssuePolicy < BasePolicy
  def rules
    delegate! @subject.project
  end
end
