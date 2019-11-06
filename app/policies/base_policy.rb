# frozen_string_literal: true

require_dependency 'declarative_policy'

class BasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) do
    if Feature.enabled?(:user_mode_in_session)
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

  rule { external_authorization_enabled & ~can?(:read_all_resources) }.policy do
    prevent :read_cross_project
  end

  rule { admin }.enable :read_all_resources

  rule { default }.enable :read_cross_project
end

BasePolicy.prepend_if_ee('EE::BasePolicy')
