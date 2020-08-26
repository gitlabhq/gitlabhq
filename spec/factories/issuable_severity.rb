# frozen_string_literal: true

FactoryBot.define do
  factory :issuable_severity do
    association :issue, factory: :incident
  end
end
