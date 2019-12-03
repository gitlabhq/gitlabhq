# frozen_string_literal: true

class GlobalPolicy < BasePolicy
  desc "User is an internal user"
  with_options scope: :user, score: 0
  condition(:internal) { @user&.internal? }

  desc "User's access has been locked"
  with_options scope: :user, score: 0
  condition(:access_locked) { @user&.access_locked? }

  condition(:can_create_fork, scope: :user) { @user && @user.manageable_namespaces.any? { |namespace| @user.can?(:create_projects, namespace) } }

  condition(:required_terms_not_accepted, scope: :user, score: 0) do
    @user&.required_terms_not_accepted?
  end

  condition(:private_instance_statistics, score: 0) { Gitlab::CurrentSettings.instance_statistics_visibility_private? }

  rule { admin | (~private_instance_statistics & ~anonymous) }
    .enable :read_instance_statistics

  rule { anonymous }.policy do
    prevent :log_in
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
    enable :use_slash_commands
  end

  rule { blocked | internal }.policy do
    prevent :log_in
    prevent :access_api
    prevent :access_git
    prevent :receive_notifications
    prevent :use_slash_commands
  end

  rule { deactivated }.policy do
    prevent :access_git
    prevent :access_api
    prevent :receive_notifications
    prevent :use_slash_commands
  end

  rule { required_terms_not_accepted }.policy do
    prevent :access_api
    prevent :access_git
  end

  rule { can_create_group }.policy do
    enable :create_group
  end

  rule { can_create_fork }.policy do
    enable :create_fork
  end

  rule { access_locked }.policy do
    prevent :log_in
    prevent :use_slash_commands
  end

  rule { ~(anonymous & restricted_public_level) }.policy do
    enable :read_users_list
  end

  rule { ~anonymous }.policy do
    enable :read_instance_metadata
    enable :create_personal_snippet
  end

  rule { admin }.policy do
    enable :read_custom_attribute
    enable :update_custom_attribute
  end

  rule { external_user }.prevent :create_personal_snippet
end

GlobalPolicy.prepend_if_ee('EE::GlobalPolicy')
