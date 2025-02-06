# frozen_string_literal: true

class GlobalPolicy < BasePolicy
  desc "User is an internal user"
  with_options scope: :user, score: 0
  condition(:internal) { @user&.internal? }

  desc "User's access has been locked"
  with_options scope: :user, score: 0
  condition(:access_locked) { @user&.access_locked? }

  condition(:required_terms_not_accepted, scope: :user, score: 0) do
    @user&.required_terms_not_accepted?
  end

  condition(:can_create_group_and_projects, scope: :user) { @user&.allow_user_to_create_group_and_project? }

  condition(:password_expired, scope: :user) do
    @user&.password_expired_if_applicable?
  end

  condition(:project_bot, scope: :user) { @user&.project_bot? }
  condition(:migration_bot, scope: :user) { @user&.migration_bot? }

  condition(:service_account, scope: :user) { @user&.service_account? }

  condition(:bot, scope: :user) { @user&.bot? }

  # By default bots should not be allowed to use quick actions as they have too many permissions and it can lead to
  # surprises. We should scope down this allowlist over time as we confirm if these bots actually need to use quick
  # actions.
  condition(:bot_with_quick_actions_permitted) do
    @user.alert_bot? ||
      @user.project_bot? ||
      @user.support_bot? ||
      @user.admin_bot? ||
      @user.service_account?
  end

  condition(:service_account_generated_email) do
    @user&.service_account? &&
      @user.email.start_with?(User::SERVICE_ACCOUNT_PREFIX) &&
      @user.email.end_with?(User::NOREPLY_EMAIL_DOMAIN)
  end

  rule { bot & ~bot_with_quick_actions_permitted }.policy do
    prevent :use_quick_actions
  end

  rule { anonymous }.policy do
    prevent :log_in
    prevent :receive_notifications
    prevent :use_quick_actions
    prevent :create_group
    prevent :create_organization
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

  rule { blocked | (internal & ~migration_bot & ~security_bot & ~security_policy_bot) }.policy do
    prevent :access_git
  end

  rule { project_bot | service_account }.policy do
    prevent :log_in
  end

  rule { project_bot | service_account_generated_email }.policy do
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

  rule { ~can_create_group_and_projects }.prevent :create_group

  rule { can_create_organization }.policy do
    enable :create_organization
  end

  rule { can?(:create_group) }.policy do
    enable :create_group_with_default_branch_protection
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
    enable :create_instance_runner
    enable :read_web_hook
    enable :admin_web_hook

    # Admin pages
    enable :read_admin_audit_log
    enable :read_admin_background_jobs
    enable :read_admin_background_migrations
    enable :read_admin_cicd
    enable :read_admin_health_check
    enable :read_admin_metrics_dashboard
    enable :read_admin_system_information
  end

  # We can't use `read_statistics` because the user may have different permissions for different projects
  rule { admin }.enable :use_project_statistics_filters

  rule { external_user }.prevent :create_snippet
end

GlobalPolicy.prepend_mod_with('GlobalPolicy')
