# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  include GitlabRecaptcha
  include Gitlab::Tracking::Helpers::WeakPasswordErrorEvent

  skip_before_action :require_no_authentication, only: [:edit, :update]

  prepend_before_action :check_recaptcha, only: :create
  before_action :load_recaptcha, only: :new
  before_action :resource_from_email, only: [:create]
  before_action :check_password_authentication_available, only: [:create]
  before_action :throttle_reset, only: [:create]

  feature_category :system_access

  # rubocop: disable CodeReuse/ActiveRecord
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
        flash[:alert] = _('Your password reset token has expired.')
        redirect_to(new_user_password_url(user_email: user['email']))
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def update
    super do |resource|
      if resource.valid?
        resource.password_automatically_set = false
        resource.password_expires_at = nil
        resource.save(validate: false) if resource.changed?
      else
        log_audit_reset_failure(@user)
        track_weak_password_error(@user, self.class.name, 'create')
      end
    end
  end

  protected

  # overriden in EE
  def log_audit_reset_failure(_user); end

  def resource_from_email
    self.resource = resource_class.find_by_email(resource_params[:email].to_s)
  end

  def check_password_authentication_available
    return if Gitlab::CurrentSettings.password_authentication_enabled?

    redirect_to after_sending_reset_password_instructions_path_for(resource_name),
      alert: _("Password authentication is unavailable.")
  end

  def check_recaptcha
    return unless resource_params[:email].present?

    super
  end

  def throttle_reset
    return unless resource && resource.recently_sent_password_reset?

    # Throttle reset attempts, but return a normal message to
    # avoid user enumeration attack.
    redirect_to new_user_session_path,
      notice: I18n.t('devise.passwords.send_paranoid_instructions')
  end

  def context_user
    resource
  end

  def resource_params
    super.permit(:email, :reset_password_token, :password, :password_confirmation)
  end
end

PasswordsController.prepend_mod_with('PasswordsController')
