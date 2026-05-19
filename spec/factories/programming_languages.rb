# frozen_string_literal: true

FactoryBot.define do
  factory :programming_language do
    name { 'Ruby' }
    color { '#123456' }
    sequence(:language_id) { |n| n + 100 }
  end
end
