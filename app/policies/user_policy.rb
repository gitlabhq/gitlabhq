class UserPolicy < BasePolicy
  include Gitlab::CurrentSettings

  desc "The application is restricted from public visibility"
  condition(:restricted_public_level) do
    current_application_settings.restricted_visibility_levels.include?(Gitlab::VisibilityLevel::PUBLIC)
  end

  desc "The current user is the user in question"
  condition(:own_user, score: 0) { @subject == @user }

  desc "This is the ghost user"
  condition(:subject_ghost, scope: :subject) { @subject.ghost? }

  rule { ~restricted_public_level }.enable :read_user
  rule { ~anonymous }.enable :read_user

  rule { own_user | admin }.enable :destroy_user
  rule { subject_ghost }.prevent :destroy_user
end
