# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast_message, class: 'System::BroadcastMessage' do
    message { "MyText" }
    starts_at { 1.day.ago }
    ends_at { 1.day.from_now }
    show_in_cli { true }

    broadcast_type { :banner }

    trait :expired do
      starts_at { 5.days.ago }
      ends_at { 3.days.ago }
    end

    trait :future do
      starts_at { 5.days.from_now }
      ends_at { 6.days.from_now }
    end

    trait :notification do
      broadcast_type { :notification }
    end
  end
end
