# frozen_string_literal: true

module Users
  class CreditCardValidation < ApplicationRecord
    self.table_name = 'user_credit_card_validations'

    belongs_to :user
  end
end
