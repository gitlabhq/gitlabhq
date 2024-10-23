# frozen_string_literal: true

module Users
  class PhoneNumberValidation < ApplicationRecord
    # SMS send attempts subsequent to the first one will have wait times of 1
    # min, 3 min, 5 min after each one respectively. Wait time between the fifth
    # attempt and so on will be 10 minutes.
    SMS_SEND_WAIT_TIMES = [1.minute, 3.minutes, 5.minutes, 10.minutes].freeze

    self.primary_key = :user_id
    self.table_name = 'user_phone_number_validations'

    ignore_column :verification_attempts, remove_with: '16.7', remove_after: '2023-11-17'

    belongs_to :user
    belongs_to :banned_user, class_name: '::Users::BannedUser', foreign_key: :user_id

    validates :country, presence: true, length: { maximum: 3 }

    validates :international_dial_code,
      presence: true,
      numericality: {
        only_integer: true,
        greater_than_or_equal_to: 1,
        less_than_or_equal_to: 999
      }

    validates :phone_number,
      presence: true,
      format: {
        with: /\A\d+\Z/,
        message: ->(_object, _data) { _('can contain only digits') }
      },
      length: { maximum: 12 }

    validates :telesign_reference_xid, length: { maximum: 255 }

    scope :for_user, ->(user_id) { where(user_id: user_id) }

    scope :similar_to, ->(phone_number_validation) do
      where(
        international_dial_code: phone_number_validation.international_dial_code,
        phone_number: phone_number_validation.phone_number
      )
    end

    def similar_records
      self.class.similar_to(self).includes(:user)
    end

    def duplicate_records
      self.class.similar_to(self).where.not(user: user)
    end

    def self.related_to_banned_user?(international_dial_code, phone_number)
      joins(:banned_user)
      .where(
        international_dial_code: international_dial_code,
        phone_number: phone_number
      )
      .where.not(validated_at: nil)
      .exists?
    end

    def self.by_reference_id(ref_id)
      find_by(telesign_reference_xid: ref_id)
    end

    def validated?
      validated_at.present?
    end

    def sms_send_allowed_after
      # first send is allowed anytime
      return if sms_send_count < 1
      return unless sms_sent_at

      max_wait_time = SMS_SEND_WAIT_TIMES.last
      wait_time = SMS_SEND_WAIT_TIMES.fetch(sms_send_count - 1, max_wait_time)

      sms_sent_at + wait_time
    end
  end
end
