# frozen_string_literal: true

module Users
  class PhoneNumberValidation < ApplicationRecord
    self.primary_key = :user_id
    self.table_name = 'user_phone_number_validations'

    belongs_to :user, foreign_key: :user_id
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
        message: -> (object, data) { _('can contain only digits') }
      },
      length: { maximum: 12 }

    validates :telesign_reference_xid, length: { maximum: 255 }

    scope :for_user, -> (user_id) { where(user_id: user_id) }

    def self.related_to_banned_user?(international_dial_code, phone_number)
      joins(:banned_user).where(
        international_dial_code: international_dial_code,
        phone_number: phone_number
      ).exists?
    end

    def validated?
      validated_at.present?
    end
  end
end
