# frozen_string_literal: true

class BasePolicy < DeclarativePolicy::Base
  # rubocop:disable Gitlab/AvoidCurrentOrganization -- Needed for prevent_all policy
  desc "Subject belongs to current organization"
  condition(:in_current_organization) do
    next true unless Feature.enabled?(:current_organization_policy, Feature.current_request)
    next true if user_is_user? && @user.admin?
    next true unless Current.organization_assigned && Current.organization
    next true if @subject.is_a? Organizations::Organization

    sharding_attribute = @subject.class.try(:sharding_keys)&.key("organizations")
    next true unless sharding_attribute
    next true unless @subject.respond_to?(sharding_attribute)

    # rubocop:disable GitlabSecurity/PublicSend -- Sharding attribute can have different names
    organization_id = @subject.public_send(sharding_attribute)
    # rubocop:enable GitlabSecurity/PublicSend
    next true if organization_id.nil?

    organization_id == Current.organization.id
  end
  # rubocop:enable Gitlab/AvoidCurrentOrganization

  desc "User is an instance admin"
  with_options scope: :user, score: 0
  condition(:admin) do
    next false if @user&.from_ci_job_token?
    next true if user_is_user? && @user.admin_bot?

    if Gitlab::CurrentSettings.admin_mode
      @user&.admin? && Gitlab::Auth::CurrentUserMode.new(@user).admin_mode?
    else
      @user&.admin?
    end
  end

  desc "The current instance is a GitLab Dedicated instance"
  condition :gitlab_dedicated do
    Gitlab::CurrentSettings.gitlab_dedicated_instance?
  end

  desc "User is blocked"
  with_options scope: :user, score: 0
  condition(:blocked) { @user&.blocked? }

  desc "User is deactivated"
  with_options scope: :user, score: 0
  condition(:deactivated) { @user&.deactivated? }

  desc "User is bot"
  with_options scope: :user, score: 0
  condition(:bot) { @user&.bot? }

  desc "User is alert bot"
  with_options scope: :user, score: 0
  condition(:alert_bot) { @user&.alert_bot? }

  desc "User is support bot"
  with_options scope: :user, score: 0
  condition(:support_bot) { @user&.support_bot? }

  desc "User is security bot"
  with_options scope: :user, score: 0
  condition(:security_bot) { @user&.security_bot? }

  desc "User is security policy bot"
  with_options scope: :user, score: 0
  condition(:security_policy_bot) { false }

  desc "User is automation bot"
  with_options scope: :user, score: 0
  condition(:automation_bot) { @user&.automation_bot? }

  desc "User is placeholder"
  with_options scope: :user, score: 0
  condition(:placeholder_user) { @user.try(:placeholder?) || false }

  desc "Import user"
  with_options scope: :user, score: 0
  condition(:import_user) { @user.try(:import_user?) || false }

  desc "User email is unconfirmed or user account is locked"
  with_options scope: :user, score: 0
  condition(:inactive) { @user&.confirmation_required_on_sign_in? || @user&.access_locked? }

  with_options scope: :user, score: 0
  condition(:external_user) { @user.nil? || @user.external? }

  with_options scope: :user, score: 0
  condition(:can_create_group) { @user&.can_create_group }

  desc 'User can create an organization'
  with_options scope: :global, score: 0
  condition(:can_create_organization) { Gitlab::CurrentSettings.can_create_organization }

  desc "Only admins can destroy projects"
  condition(:owner_cannot_destroy_project, scope: :global) do
    ::Gitlab::CurrentSettings.current_application_settings
      .default_project_deletion_protection
  end

  desc "The application is restricted from public visibility"
  condition(:restricted_public_level, scope: :global) do
    Gitlab::CurrentSettings.current_application_settings.restricted_visibility_levels.include?(Gitlab::VisibilityLevel::PUBLIC)
  end

  condition(:external_authorization_enabled, scope: :global, score: 0) do
    ::Gitlab::ExternalAuthorization.perform_check?
  end

  rule { ~in_current_organization }.prevent_all

  rule { external_authorization_enabled & ~can?(:read_all_resources) }.policy do
    prevent :read_cross_project
  end

  rule { admin }.policy do
    # Only for actual administrator accounts, behavior affected by admin mode application setting
    enable :admin_all_resources
    # Policy extended in EE to also enable auditors
    enable :read_all_resources
    enable :change_repository_storage
  end

  rule { gitlab_dedicated & admin }.policy do
    enable :read_dedicated_hosted_runner_usage
  end

  rule { default }.enable :read_cross_project

  condition(:is_gitlab_com, score: 0, scope: :global) { ::Gitlab.com? }

  rule { placeholder_user }.prevent_all
  rule { import_user }.prevent_all

  private

  def user_is_user?
    user.is_a?(User)
  end

  def owns_organization?(org)
    return false unless org.present?
    return false unless user_is_user?

    # Admin is often automatically assigned as an owner of the default organization
    # so we only want to return true here if an admin user is running in admin mode
    return false if admin_mode_required?

    # Load the owners with a single query.
    org.owner_user_ids.include?(@user.id)
  end

  def admin_mode_required?
    return false unless @user&.admin?
    return false unless Gitlab::CurrentSettings.admin_mode

    !Gitlab::Auth::CurrentUserMode.new(@user).admin_mode?
  end
end

BasePolicy.prepend_mod_with('BasePolicy')
