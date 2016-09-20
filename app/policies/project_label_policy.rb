class ProjectLabelPolicy < BasePolicy
  def rules
    can! :admin_label if Ability.allowed?(@user, :admin_label, @subject.project)
  end
end
