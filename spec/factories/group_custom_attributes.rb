# frozen_string_literal: true

FactoryBot.define do
  factory :group_custom_attribute do
    group
    sequence(:key) { |n| "key#{n}" }
    sequence(:value) { |n| "value#{n}" }
  end
end
