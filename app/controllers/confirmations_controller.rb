class ConfirmationsController < Devise::ConfirmationsController
  def almost_there
    flash[:notice] = nil
    render layout: "devise_empty"
  end

  protected

  def after_resending_confirmation_instructions_path_for(resource)
    users_almost_there_path
  end

  def after_confirmation_path_for(resource_name, resource)
    # incoming resource can either be a :user or an :email
    if signed_in?(:user)
      after_sign_in(resource)
    else
      Gitlab::AppLogger.info("Email Confirmed: username=#{resource.username} email=#{resource.email} ip=#{request.remote_ip}")
      flash[:notice] += " Please sign in."
      new_session_path(:user, anchor: 'login-pane')
    end
  end

  def after_sign_in(resource)
    after_sign_in_path_for(resource)
  end
end
