# frozen_string_literal: true

class UserPresenter < Gitlab::View::Presenter::Delegated
  presents ::User, as: :user

  def group_memberships
    should_be_private? ? GroupMember.none : user.group_members
  end

  def project_memberships
    should_be_private? ? ProjectMember.none : user.project_members
  end

  def preferences_gitpod_path
    profile_preferences_path(anchor: 'user_gitpod_enabled') if application_gitpod_enabled?
  end

  def profile_enable_gitpod_path
    user_settings_profile_path(user: { gitpod_enabled: true }) if application_gitpod_enabled?
  end

  delegator_override :saved_replies
  def saved_replies
    return ::Users::SavedReply.none unless current_user.can?(:read_saved_replies, user)

    user.saved_replies
  end

  private

  def can?(...)
    user.can?(...)
  end

  def should_be_private?
    !Ability.allowed?(current_user, :read_user_profile, user)
  end

  def application_gitpod_enabled?
    Gitlab::CurrentSettings.gitpod_enabled
  end
end
