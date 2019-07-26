# frozen_string_literal: true

FactoryBot.define do
  factory :user_custom_attribute do
    user
    sequence(:key) { |n| "key#{n}" }
    sequence(:value) { |n| "value#{n}" }
  end
end
