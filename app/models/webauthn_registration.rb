# frozen_string_literal: true

# Registration information for WebAuthn credentials

class WebauthnRegistration < ApplicationRecord
  belongs_to :user

  validates :credential_xid, :public_key, :name, :counter, presence: true
  validates :counter,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2**32 - 1 }
end
