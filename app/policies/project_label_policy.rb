class ProjectLabelPolicy < BasePolicy
  def rules
    delegate! @subject.project
  end
end
