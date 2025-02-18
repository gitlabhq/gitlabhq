# frozen_string_literal: true

FactoryBot.define do
  factory :description_version do
    description { generate(:title) }

    trait :issue do
      association :issue
    end

    trait :merge_request do
      association :merge_request
    end
  end
end
