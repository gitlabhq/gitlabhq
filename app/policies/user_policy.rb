# frozen_string_literal: true

class UserPolicy < BasePolicy
  desc "The current user is the user in question"
  condition(:user_is_self, score: 0) { @subject == @user }

  desc "This is the ghost user"
  condition(:subject_ghost, scope: :subject, score: 0) { @subject.ghost? }

  desc "The profile is private"
  condition(:private_profile, scope: :subject, score: 0) { private_profile? }

  desc "The user is blocked"
  condition(:blocked_user, scope: :subject, score: 0) { @subject.blocked? }

  desc "The user is unconfirmed"
  condition(:unconfirmed_user, scope: :subject, score: 0) { !@subject.confirmed? }

  rule { ~restricted_public_level }.enable :read_user
  rule { ~anonymous }.enable :read_user

  rule { ~subject_ghost & (user_is_self | admin) }.policy do
    enable :destroy_user
    enable :update_user
    enable :update_user_status
    enable :create_saved_replies
    enable :update_saved_replies
    enable :destroy_saved_replies
    enable :read_personal_access_token
    enable :read_user_membership_counts
    enable :read_user_groups
    enable :read_user_organizations
    enable :read_saved_replies
    enable :read_user_email_address
    enable :admin_user_email_address
    enable :make_profile_private
    enable :read_user_preference
  end

  rule { user_is_self | admin }.policy do
    enable :disable_two_factor
    enable :disable_passkey
  end

  rule { default }.enable :read_user_profile
  rule { (private_profile | blocked_user | unconfirmed_user) & ~(user_is_self | admin) }.prevent :read_user_profile
  rule { (user_is_self | admin) & ~blocked }.enable :create_personal_access_token
  rule { (user_is_self | admin) & ~blocked }.enable :rotate_personal_access_token
  rule { (user_is_self | admin) & ~blocked }.enable :get_user_associations_count

  desc "The user has admin_service_accounts on the target service account's provisioning scope"
  condition(:can_admin_target_service_account) do
    next false unless @user && @subject.service_account?

    scope = @subject.provisioned_by_group || @subject.provisioned_by_project
    next false unless scope

    can?(:admin_service_accounts, scope)
  end

  rule { can_admin_target_service_account & ~blocked }.policy do
    enable :create_personal_access_token
    enable :rotate_personal_access_token
  end

  rule { admin }.policy do
    enable :read_custom_attribute
    enable :update_custom_attribute
    enable :delete_custom_attribute
  end

  def private_profile?
    @subject.private_profile?
  end
end

UserPolicy.prepend_mod_with('UserPolicy')
