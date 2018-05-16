class GlobalPolicy < BasePolicy
  desc "User is blocked"
  with_options scope: :user, score: 0
  condition(:blocked) { @user.blocked? }

  desc "User is an internal user"
  with_options scope: :user, score: 0
  condition(:internal) { @user.internal? }

  desc "User's access has been locked"
  with_options scope: :user, score: 0
  condition(:access_locked) { @user.access_locked? }

  condition(:can_create_fork, scope: :user) { @user.manageable_namespaces.any? { |namespace| @user.can?(:create_projects, namespace) } }

  rule { anonymous }.policy do
    prevent :log_in
    prevent :access_api
    prevent :access_git
    prevent :receive_notifications
    prevent :use_quick_actions
    prevent :create_group
  end

  rule { default }.policy do
    enable :log_in
    enable :access_api
    enable :access_git
    enable :receive_notifications
    enable :use_quick_actions
  end

  rule { blocked | internal }.policy do
    prevent :log_in
    prevent :access_api
    prevent :access_git
    prevent :receive_notifications
    prevent :use_quick_actions
  end

  rule { can_create_group }.policy do
    enable :create_group
  end

  rule { can_create_fork }.policy do
    enable :create_fork
  end

  rule { access_locked }.policy do
    prevent :log_in
  end

  rule { ~(anonymous & restricted_public_level) }.policy do
    enable :read_users_list
  end

  rule { admin }.policy do
    enable :read_custom_attribute
    enable :update_custom_attribute
  end
end
