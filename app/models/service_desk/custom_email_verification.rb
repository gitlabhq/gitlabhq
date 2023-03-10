# frozen_string_literal: true

module ServiceDesk
  class CustomEmailVerification < ApplicationRecord
    enum state: {
      running: 0,
      verified: 1,
      error: 2
    }, _default: 'running'

    enum error: {
      incorrect_token: 0,
      incorrect_from: 1,
      mail_not_received_within_timeframe: 2,
      invalid_credentials: 3,
      smtp_host_issue: 4
    }

    TIMEFRAME = 30.minutes

    attr_encrypted :token,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      encode: false,
      encode_iv: false

    belongs_to :project
    belongs_to :triggerer, class_name: 'User', optional: true

    validates :project, presence: true
    validates :state, presence: true

    delegate :service_desk_setting, to: :project

    class << self
      def generate_token
        SecureRandom.alphanumeric(12)
      end
    end

    def accepted_until
      return unless running?
      return unless triggered_at.present?

      TIMEFRAME.since(triggered_at)
    end

    def in_timeframe?
      return false unless running?

      !!accepted_until&.future?
    end
  end
end
