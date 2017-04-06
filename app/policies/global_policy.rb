class GlobalPolicy < BasePolicy
  desc "User is blocked"
  condition(:blocked, scope: :user) { @user.blocked? }

  desc "User is an internal user"
  condition(:internal, scope: :user) { @user.internal? }

  desc "User's access has been locked"
  condition(:access_locked, scope: :user) { @user.access_locked? }

  rule { anonymous }.prevent_all

  rule { default }.policy do
    enable :read_users_list
    enable :log_in
    enable :access_api
    enable :access_git
    enable :receive_notifications
    enable :use_slash_commands
  end

  rule { blocked | internal }.policy do
    prevent :log_in
    prevent :access_api
    prevent :access_git
    prevent :receive_notifications
    prevent :use_slash_commands
  end

  rule { can_create_group }.policy do
    enable :create_group
  end

  rule { access_locked }.policy do
    prevent :log_in
  end
end
