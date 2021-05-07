# frozen_string_literal: true

module API
  module Entities
    class UserCreditCardValidations < Grape::Entity
      expose :user_id, :credit_card_validated_at
    end
  end
end
