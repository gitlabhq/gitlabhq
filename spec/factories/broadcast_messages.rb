# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast_message do
    message "MyText"
    starts_at { 1.day.ago }
    ends_at { 1.day.from_now }

    trait :expired do
      starts_at { 5.days.ago }
      ends_at { 3.days.ago }
    end

    trait :future do
      starts_at { 5.days.from_now }
      ends_at { 6.days.from_now }
    end
  end
end
