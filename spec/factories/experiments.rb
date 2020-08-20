# frozen_string_literal: true

FactoryBot.define do
  factory :experiment do
    name { generate(:title) }
  end
end
