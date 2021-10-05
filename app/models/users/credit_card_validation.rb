# frozen_string_literal: true

module Users
  class CreditCardValidation < ApplicationRecord
    RELEASE_DAY = Date.new(2021, 5, 17)

    self.table_name = 'user_credit_card_validations'

    belongs_to :user

    validates :holder_name, length: { maximum: 26 }
    validates :last_digits, allow_nil: true, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 9999
    }
  end
end
