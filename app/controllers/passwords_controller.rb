class PasswordsController < Devise::PasswordsController

  def create
    email = resource_params[:email]
    self.resource = resource_class.find_by_email(email)

    if resource && resource.ldap_user?
      flash[:alert] = "Cannot reset password for LDAP user."
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) and return
    end

    unless can_send_reset_email?
      flash[:alert] = "Instructions about how to reset your password have already been sent recently. Please wait a few minutes to try again."
      respond_with({}, location: new_password_path(resource_name)) and return
    end

    super
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

  private

  def can_send_reset_email?
    resource && (resource.reset_password_sent_at.blank? ||
                 resource.reset_password_sent_at < 1.minute.ago)
  end
end
