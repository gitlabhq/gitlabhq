class ConfirmationsController < Devise::ConfirmationsController

  protected

  def after_confirmation_path_for(resource_name, resource)
    if signed_in?(resource_name)
      after_sign_in_path_for(resource)
    else
      sign_in(resource)
      if signed_in?(resource_name)
        after_sign_in_path_for(resource)
      else
        new_session_path(resource_name)
      end
    end
  end
end
