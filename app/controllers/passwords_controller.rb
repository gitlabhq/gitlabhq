class PasswordsController < Devise::PasswordsController

  def create
    email = resource_params[:email]
    resource_found = resource_class.find_by_email(email)
    if resource_found && resource_found.ldap_user?
      flash[:alert] = "Cannot reset password for LDAP user."
      respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name)) and return
    end

    self.resource = resource_class.send_reset_password_instructions(resource_params)
    if successfully_sent?(resource)
      respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end
end
