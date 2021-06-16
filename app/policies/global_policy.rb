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

  condition(:password_expired, scope: :user) do
    @user&.password_expired_if_applicable?
  end

  condition(:project_bot, scope: :user) { @user&.project_bot? }
  condition(:migration_bot, scope: :user) { @user&.migration_bot? }

  rule { anonymous }.policy do
    prevent :log_in
    prevent :receive_notifications
    prevent :use_quick_actions
    prevent :create_group
    prevent :execute_graphql_mutation
  end

  rule { default }.policy do
    enable :log_in
    enable :access_api
    enable :access_git
    enable :receive_notifications
    enable :use_quick_actions
    enable :use_slash_commands
    enable :execute_graphql_mutation
  end

  rule { inactive }.policy do
    prevent :log_in
    prevent :access_api
    prevent :access_git
    prevent :use_slash_commands
  end

  rule { blocked | internal }.policy do
    prevent :log_in
    prevent :access_api
    prevent :receive_notifications
    prevent :use_slash_commands
  end

  rule { ~can?(:access_api) }.prevent :execute_graphql_mutation

  rule { blocked | (internal & ~migration_bot & ~security_bot) }.policy do
    prevent :access_git
  end

  rule { project_bot }.policy do
    prevent :log_in
    prevent :receive_notifications
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

  rule { password_expired }.policy do
    prevent :access_api
    prevent :access_git
    prevent :use_slash_commands
  end

  rule { can_create_group }.policy do
    enable :create_group
  end

  rule { can?(:create_group) }.policy do
    enable :create_group_with_default_branch_protection
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
    enable :create_snippet
  end

  rule { admin }.policy do
    enable :read_custom_attribute
    enable :update_custom_attribute
    enable :approve_user
    enable :reject_user
    enable :read_usage_trends_measurement
    enable :update_runners_registration_token
  end

  # We can't use `read_statistics` because the user may have different permissions for different projects
  rule { admin }.enable :use_project_statistics_filters

  rule { external_user }.prevent :create_snippet
end

GlobalPolicy.prepend_mod_with('GlobalPolicy')
