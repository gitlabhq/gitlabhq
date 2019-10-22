# frozen_string_literal: true

FactoryBot.define do
  factory :term_agreement do
    term
    user
  end

  trait :declined do
    accepted { false }
  end

  trait :accepted do
    accepted { true }
  end
end
