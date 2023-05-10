# frozen_string_literal: true

module Users
  class CreditCardValidation < ApplicationRecord
    RELEASE_DAY = Date.new(2021, 5, 17)

    self.table_name = 'user_credit_card_validations'

    belongs_to :user
    belongs_to :banned_user, class_name: '::Users::BannedUser', foreign_key: :user_id,
      inverse_of: :credit_card_validation

    validates :holder_name, length: { maximum: 50 }
    validates :network, length: { maximum: 32 }
    validates :last_digits, allow_nil: true, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 9999
    }

    scope :by_banned_user, -> { joins(:banned_user) }
    scope :similar_by_holder_name, ->(holder_name) do
      if holder_name.present?
        where('lower(holder_name) = lower(:value)', value: holder_name)
      else
        none
      end
    end
    scope :similar_to, ->(credit_card_validation) do
      where(
        expiration_date: credit_card_validation.expiration_date,
        last_digits: credit_card_validation.last_digits,
        network: credit_card_validation.network
      )
    end

    def similar_records
      self.class.similar_to(self).order(credit_card_validated_at: :desc).includes(:user)
    end

    def similar_holder_names_count
      self.class.similar_by_holder_name(holder_name).count
    end

    def used_by_banned_user?
      self.class.by_banned_user.similar_to(self).similar_by_holder_name(holder_name).exists?
    end
  end
end
