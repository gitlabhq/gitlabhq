# frozen_string_literal: true

# Concern that overrides the Devise methods
# to send reset password instructions to any verified user email
module RecoverableByAnyEmail
  extend ActiveSupport::Concern

  class_methods do
    def send_reset_password_instructions(attributes = {})
      return super unless Feature.enabled?(:password_reset_any_verified_email)

      email = attributes.delete(:email)
      super unless email

      recoverable = by_email_with_errors(email)
      recoverable.send_reset_password_instructions(to: email) if recoverable&.persisted?
      recoverable
    end

    private

    def by_email_with_errors(email)
      record = find_by_any_email(email, confirmed: true) || new
      record.errors.add(:email, :invalid) unless record.persisted?
      record
    end
  end

  def send_reset_password_instructions(opts = {})
    return super() unless Feature.enabled?(:password_reset_any_verified_email)

    token = set_reset_password_token
    send_reset_password_instructions_notification(token, opts)

    token
  end

  private

  def send_reset_password_instructions_notification(token, opts = {})
    return super(token) unless Feature.enabled?(:password_reset_any_verified_email)

    send_devise_notification(:reset_password_instructions, token, opts)
  end
end
