# frozen_string_literal: true

# Registration information for WebAuthn credentials

class WebauthnRegistration < ApplicationRecord
  belongs_to :user

  validates :credential_xid, :public_key, :counter, :authentication_mode, presence: true
  validates :passkey_eligible, inclusion: { in: [true, false] }
  validates :name, length: { minimum: 0, allow_nil: false }
  validates :counter,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: (2**32) - 1 }

  validate :ensure_passkey_eligibility, if: :passwordless?

  enum :authentication_mode, {
    passwordless: 1,
    second_factor: 2
  }

  scope :passkey, -> { passwordless }
  scope :second_factor_authenticator, -> { second_factor }

  def passkey?
    passwordless?
  end

  private

  def ensure_passkey_eligibility
    errors.add(:base, _('This credential is not passkey eligible')) unless passkey_eligible?
  end
end
