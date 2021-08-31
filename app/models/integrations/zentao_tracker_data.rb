# frozen_string_literal: true

module Integrations
  class ZentaoTrackerData < ApplicationRecord
    belongs_to :integration, inverse_of: :zentao_tracker_data, foreign_key: :integration_id
    delegate :activated?, to: :integration
    validates :integration, presence: true

    scope :encryption_options, -> do
      {
        key: Settings.attr_encrypted_db_key_base_32,
        encode: true,
        mode: :per_attribute_iv,
        algorithm: 'aes-256-gcm'
      }
    end

    attr_encrypted :url, encryption_options
    attr_encrypted :api_url, encryption_options
    attr_encrypted :zentao_product_xid, encryption_options
    attr_encrypted :api_token, encryption_options
  end
end
