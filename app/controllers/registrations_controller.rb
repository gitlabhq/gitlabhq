class RegistrationsController < Devise::RegistrationsController
  before_filter :signup_enabled?

  private

  def signup_enabled?
    redirect_to new_user_session_path unless Gitlab.config.gitlab.signup_enabled
  end
end