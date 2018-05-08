class UserPolicy < BasePolicy
  desc "The current user is the user in question"
  condition(:user_is_self, score: 0) { @subject == @user }

  desc "This is the ghost user"
  condition(:subject_ghost, scope: :subject, score: 0) { @subject.ghost? }

  rule { ~restricted_public_level }.enable :read_user
  rule { ~anonymous }.enable :read_user

  rule { user_is_self | admin }.enable :destroy_user
  rule { subject_ghost }.prevent :destroy_user
end
