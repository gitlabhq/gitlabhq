class GroupLabelPolicy < BasePolicy
  def rules
    can! :admin_label if Ability.allowed?(@user, :admin_label, @subject.group)
  end
end
