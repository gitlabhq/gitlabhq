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
    enable :read_user_personal_access_tokens
    enable :read_group_count
    enable :read_user_groups
    enable :read_user_organizations
    enable :read_saved_replies
    enable :read_user_email_address
    enable :admin_user_email_address
    enable :make_profile_private
    enable :read_user_preference
  end

  rule { default }.enable :read_user_profile
  rule { (private_profile | blocked_user | unconfirmed_user) & ~(user_is_self | admin) }.prevent :read_user_profile
  rule { user_is_self | admin }.enable :disable_two_factor
  rule { (user_is_self | admin) & ~blocked }.enable :create_user_personal_access_token
  rule { (user_is_self | admin) & ~blocked }.enable :manage_user_personal_access_token
  rule { (user_is_self | admin) & ~blocked }.enable :get_user_associations_count

  def private_profile?
    @subject.private_profile?
  end
end

UserPolicy.prepend_mod_with('UserPolicy')
