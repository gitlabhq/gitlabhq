# frozen_string_literal: true

# Registration information for WebAuthn credentials

class WebauthnRegistration < ApplicationRecord
  include IgnorableColumns

  ignore_column :u2f_registration_id, remove_with: '16.2', remove_after: '2023-06-22'

  belongs_to :user

  validates :credential_xid, :public_key, :counter, presence: true
  validates :name, length: { minimum: 0, allow_nil: false }
  validates :counter,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2**32 - 1 }
end
