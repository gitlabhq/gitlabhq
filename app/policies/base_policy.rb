# frozen_string_literal: true

class BasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) do
    if Gitlab::CurrentSettings.admin_mode
      Gitlab::Auth::CurrentUserMode.new(@user).admin_mode?
    else
      @user&.admin?
    end
  end

  desc "User is blocked"
  with_options scope: :user, score: 0
  condition(:blocked) { @user&.blocked? }

  desc "User is deactivated"
  with_options scope: :user, score: 0
  condition(:deactivated) { @user&.deactivated? }

  desc "User is support bot"
  with_options scope: :user, score: 0
  condition(:support_bot) { @user&.support_bot? }

  desc "User is security bot"
  with_options scope: :user, score: 0
  condition(:security_bot) { @user&.security_bot? }

  desc "User is automation bot"
  with_options scope: :user, score: 0
  condition(:automation_bot) { @user&.automation_bot? }

  desc "User email is unconfirmed or user account is locked"
  with_options scope: :user, score: 0
  condition(:inactive) { @user&.confirmation_required_on_sign_in? || @user&.access_locked? }

  with_options scope: :user, score: 0
  condition(:external_user) { @user.nil? || @user.external? }

  with_options scope: :user, score: 0
  condition(:can_create_group) { @user&.can_create_group }

  desc "The application is restricted from public visibility"
  condition(:restricted_public_level, scope: :global) do
    Gitlab::CurrentSettings.current_application_settings.restricted_visibility_levels.include?(Gitlab::VisibilityLevel::PUBLIC)
  end

  condition(:external_authorization_enabled, scope: :global, score: 0) do
    ::Gitlab::ExternalAuthorization.perform_check?
  end

  with_options scope: :user, score: 0
  condition(:alert_bot) { @user&.alert_bot? }

  rule { external_authorization_enabled & ~can?(:read_all_resources) }.policy do
    prevent :read_cross_project
  end

  rule { admin }.policy do
    # Only for actual administrator accounts, behaviour affected by admin mode application setting
    enable :admin_all_resources
    # Policy extended in EE to also enable auditors
    enable :read_all_resources
    enable :change_repository_storage
  end

  rule { default }.enable :read_cross_project

  condition(:is_gitlab_com, score: 0, scope: :global) { ::Gitlab.dev_env_or_com? }
end

BasePolicy.prepend_mod_with('BasePolicy')
