class PasswordsController < Devise::PasswordsController

  def create
    email = resource_params[:email]
    resource_found = resource_class.find_by_email(email)
    if resource_found && resource_found.ldap_user?
      flash[:alert] = "Cannot reset password for LDAP user."
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) and return
    end

    self.resource = resource_class.send_reset_password_instructions(resource_params)
    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  def edit
    super
    reset_password_token = Devise.token_generator.digest(
      User,
      :reset_password_token,
      resource.reset_password_token
    )

    unless reset_password_token.nil?
      user = User.where(
        reset_password_token: reset_password_token
      ).first_or_initialize

      unless user.reset_password_period_valid?
        flash[:alert] = 'Your password reset token has expired.'
        redirect_to(new_user_password_url(user_email: user['email']))
      end
    end
  end
end
