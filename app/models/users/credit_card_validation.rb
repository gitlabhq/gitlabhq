# frozen_string_literal: true

module Users
  class CreditCardValidation < ApplicationRecord
    RELEASE_DAY = Date.new(2021, 5, 17)

    self.table_name = 'user_credit_card_validations'

    belongs_to :user

    validates :holder_name, length: { maximum: 50 }
    validates :network, length: { maximum: 32 }
    validates :last_digits, allow_nil: true, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 9999
    }

    def similar_records
      self.class.where(
        expiration_date: expiration_date,
        last_digits: last_digits,
        network: network
      ).order(credit_card_validated_at: :desc).includes(:user)
    end

    def similar_holder_names_count
      return 0 unless holder_name

      self.class.where('lower(holder_name) = lower(:value)', value: holder_name).count
    end
  end
end
