# frozen_string_literal: true

FactoryBot.define do
  factory :credit_card_validation, class: 'Users::CreditCardValidation' do
    user
    sequence(:credit_card_validated_at) { |n| Time.current + n }
    expiration_date { 1.year.from_now.to_date }
    last_digits { 10 }
    holder_name { 'John Smith' }
    network { 'AmericanExpress' }
  end
end
