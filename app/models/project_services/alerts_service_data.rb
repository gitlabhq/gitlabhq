# frozen_string_literal: true

require 'securerandom'

class AlertsServiceData < ApplicationRecord
  belongs_to :service, class_name: 'AlertsService'

  validates :service, presence: true

  attr_encrypted :token,
    mode: :per_attribute_iv,
    key: Settings.attr_encrypted_db_key_base_truncated,
    algorithm: 'aes-256-gcm'
end
