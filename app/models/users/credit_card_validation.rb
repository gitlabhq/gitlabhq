# frozen_string_literal: true

module Users
  class CreditCardValidation < ApplicationRecord
    DAILY_VERIFICATION_LIMIT = 5

    self.table_name = 'user_credit_card_validations'

    attr_accessor :last_digits, :network, :holder_name, :expiration_date

    belongs_to :user
    belongs_to :banned_user, class_name: '::Users::BannedUser', foreign_key: :user_id,
      inverse_of: :credit_card_validation

    validates :holder_name, length: { maximum: 50 }
    validates :network, length: { maximum: 32 }
    validates :last_digits, allow_nil: true, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 9999
    }

    validates :zuora_payment_method_xid, length: { maximum: 50 }, uniqueness: true, allow_nil: true

    validates :stripe_setup_intent_xid, length: { maximum: 255 }, allow_nil: true
    validates :stripe_payment_method_xid, length: { maximum: 255 }, allow_nil: true
    validates :stripe_card_fingerprint, length: { maximum: 255 }, allow_nil: true

    validates :last_digits_hash, length: { maximum: 44 }
    validates :holder_name_hash, length: { maximum: 44 }
    validates :expiration_date_hash, length: { maximum: 44 }
    validates :network_hash, length: { maximum: 44 }

    scope :find_or_initialize_by_user, ->(user_id) { where(user_id: user_id).first_or_initialize }
    scope :by_banned_user, -> { joins(:banned_user) }
    scope :similar_by_holder_name, ->(holder_name_hash) do
      if holder_name_hash.present?
        where(holder_name_hash: holder_name_hash)
      else
        none
      end
    end
    scope :similar_to, ->(credit_card_validation) do
      where(
        expiration_date_hash: credit_card_validation.expiration_date_hash,
        last_digits_hash: credit_card_validation.last_digits_hash,
        network_hash: credit_card_validation.network_hash
      )
    end

    before_save :set_last_digits_hash, if: -> { last_digits.present? }
    before_save :set_holder_name_hash, if: -> { holder_name.present? }
    before_save :set_network_hash, if: -> { network.present? }
    before_save :set_expiration_date_hash, if: -> { expiration_date.present? }

    def similar_records
      self.class.similar_to(self).order(credit_card_validated_at: :desc).includes(:user)
    end

    def similar_holder_names_count
      self.class.similar_by_holder_name(holder_name_hash).count
    end

    def used_by_banned_user?
      self.class.by_banned_user.similar_to(self).similar_by_holder_name(holder_name_hash).exists?
    end

    def set_last_digits_hash
      self.last_digits_hash = Gitlab::CryptoHelper.sha256(last_digits)
    end

    def set_holder_name_hash
      self.holder_name_hash = Gitlab::CryptoHelper.sha256(holder_name.downcase)
    end

    def set_network_hash
      self.network_hash = Gitlab::CryptoHelper.sha256(network.downcase)
    end

    def set_expiration_date_hash
      self.expiration_date_hash = Gitlab::CryptoHelper.sha256(expiration_date.to_s)
    end

    def exceeded_daily_verification_limit?
      duplicate_record_count = self.class
        .where(stripe_card_fingerprint: stripe_card_fingerprint)
        .where('credit_card_validated_at > ?', 24.hours.ago)
        .count

      duplicate_record_count >= DAILY_VERIFICATION_LIMIT
    end
  end
end
