class LabelPolicy < BasePolicy
  def rules
    return unless @user

    can! :admin_label if Ability.allowed?(@user, :admin_label, @subject.project)
  end
end
