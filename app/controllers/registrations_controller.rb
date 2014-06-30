class RegistrationsController < Devise::RegistrationsController
  before_filter :signup_enabled?

  def destroy
    current_user.destroy

    respond_to do |format|
      format.html { redirect_to new_user_session_path, notice: "Account successfully removed." }
    end
  end

  protected

  def build_resource(hash=nil)
    super
  end

  private

  def signup_enabled?
    redirect_to new_user_session_path unless Gitlab.config.gitlab.signup_enabled
  end
end
