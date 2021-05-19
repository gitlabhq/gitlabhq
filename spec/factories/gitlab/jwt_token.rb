# frozen_string_literal: true

FactoryBot.define do
  factory :jwt_token, class: 'Gitlab::JWTToken' do
    skip_create

    initialize_with { new }

    trait :with_custom_payload do
      transient do
        custom_payload { {} }
      end

      after(:build) do |jwt, evaluator|
        evaluator.custom_payload.each do |key, value|
          jwt[key] = value
        end
      end
    end
  end
end
