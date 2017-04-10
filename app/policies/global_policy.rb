class GlobalPolicy < BasePolicy
  def rules
    return unless @user

    can! :create_group if @user.can_create_group
    can! :read_users_list

    unless @user.blocked? || @user.internal?
      can! :log_in unless @user.access_locked?
      can! :access_api
      can! :access_git
      can! :receive_notifications
      can! :use_slash_commands
    end
  end
end
