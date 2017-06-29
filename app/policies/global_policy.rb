class GlobalPolicy < BasePolicy
  def rules
    can! :read_users_list unless restricted_public_level?

    return unless @user

    can! :create_group if @user.can_create_group

    unless @user.blocked? || @user.internal?
      can! :log_in unless @user.access_locked?
      can! :access_api
      can! :access_git
      can! :receive_notifications
      can! :use_quick_actions
    end
  end
end
