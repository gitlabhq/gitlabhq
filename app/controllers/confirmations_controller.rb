class ConfirmationsController < Devise::ConfirmationsController
  include EE::Audit::Changes

  def almost_there
    flash[:notice] = nil
    render layout: "devise_empty"
  end

  protected

  def after_resending_confirmation_instructions_path_for(resource)
    users_almost_there_path
  end

  def after_confirmation_path_for(resource_name, resource)
    if signed_in?(resource_name)
      audit_changes(:email, as: 'email address', model: resource)

      after_sign_in_path_for(resource)
    else
      flash[:notice] += " Please sign in."
      new_session_path(resource_name)
    end
  end
end
