# frozen_string_literal: true

require_dependency 'declarative_policy'

class BasePolicy < DeclarativePolicy::Base
  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) { @user&.admin? }

  desc "User is blocked"
  with_options scope: :user, score: 0
  condition(:blocked) { @user&.blocked? }

  desc "User has access to all private groups & projects"
  with_options scope: :user, score: 0
  condition(:full_private_access) { @user&.full_private_access? }

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

  rule { external_authorization_enabled & ~full_private_access }.policy do
    prevent :read_cross_project
  end

  rule { default }.enable :read_cross_project
end
