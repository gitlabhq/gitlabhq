# frozen_string_literal: true

# == Require Email Verification module
#
# Contains functionality to handle email verification
module RequireEmailVerification
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  MAXIMUM_ATTEMPTS = 3
  UNLOCK_IN = 24.hours

  included do
    # Virtual attribute for the email verification token form
    attr_accessor :verification_token
  end

  # When overridden, do not send Devise unlock instructions when locking access.
  def lock_access!(opts = {})
    return super unless override_devise_lockable?

    super({ send_instructions: false })
  end

  protected

  # We cannot override the class methods `maximum_attempts` and `unlock_in`, because we want to
  # check for 2FA being enabled on the instance. So instead override the Devise Lockable methods
  # where those values are used.
  def attempts_exceeded?
    return super unless override_devise_lockable?

    failed_attempts >= MAXIMUM_ATTEMPTS
  end

  def lock_expired?
    return super unless override_devise_lockable?

    locked_at && locked_at < UNLOCK_IN.ago
  end

  private

  def override_devise_lockable?
    Feature.enabled?(:require_email_verification, self) &&
      !two_factor_enabled? &&
      identities.none? &&
      Feature.disabled?(:skip_require_email_verification, self, type: :ops)
  end
  strong_memoize_attr :override_devise_lockable?
end
