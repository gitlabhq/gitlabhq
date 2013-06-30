class RegistrationsController < Devise::RegistrationsController
  before_filter :signup_enabled?

  def destroy
    if current_user.owned_projects.count > 0
      redirect_to account_profile_path, alert: "Remove projects and groups before removing account." and return
    end
    current_user.destroy

    respond_to do |format|
      format.html { redirect_to new_user_session_path, notice: "Account successfully removed." }
    end
  end

  protected

  def build_resource(hash=nil)
    super
    self.resource.with_defaults
  end

  private

  def signup_enabled?
    redirect_to new_user_session_path unless Gitlab.config.gitlab.signup_enabled
  end
end
