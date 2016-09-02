class CommitStatusPolicy < BasePolicy
  def rules
    delegate! @subject.project
  end
end
