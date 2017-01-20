class GlobalPolicy < BasePolicy
  def rules
    return unless @user

    can! :create_group if @user.can_create_group && !@user.auditor?
    can! :read_users_list
  end
end
