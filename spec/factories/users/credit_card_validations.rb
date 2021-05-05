# frozen_string_literal: true

FactoryBot.define do
  factory :credit_card_validation, class: 'Users::CreditCardValidation' do
    user

    credit_card_validated_at { Time.current }
  end
end
