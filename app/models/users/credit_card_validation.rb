# frozen_string_literal: true

module Users
  class CreditCardValidation < ApplicationRecord
    RELEASE_DAY = Date.new(2021, 5, 17)

    self.table_name = 'user_credit_card_validations'

    belongs_to :user
  end
end
