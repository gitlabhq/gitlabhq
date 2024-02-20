# frozen_string_literal: true

# Concern that overrides the Devise methods to allow reset password instructions
# to be sent to any users' confirmed secondary emails.
# See https://github.com/heartcombo/devise/blob/main/lib/devise/models/recoverable.rb
module RecoverableByAnyEmail
  extend ActiveSupport::Concern

  class_methods do
    def send_reset_password_instructions(attributes = {})
      return super unless attributes[:email]

      email = Email.confirmed.find_by(email: attributes[:email].to_s)
      return super unless email

      recoverable = email.user
      return recoverable.password_auth_unavailable_error! unless recoverable.allow_password_authentication_for_web?

      recoverable.send_reset_password_instructions(to: email.email)
      recoverable
    end
  end

  def send_reset_password_instructions(opts = {})
    token = set_reset_password_token

    send_reset_password_instructions_notification(token, opts)

    token
  end

  def password_auth_unavailable_error!
    errors.add(:password, :unavailable, message: _('Password authentication is unavailable.'))
    self
  end

  protected

  def send_reset_password_instructions_notification(token, opts = {})
    send_devise_notification(:reset_password_instructions, token, opts)
  end
end
