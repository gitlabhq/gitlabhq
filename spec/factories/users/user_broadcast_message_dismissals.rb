# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast_message_dismissal, class: 'Users::BroadcastMessageDismissal' do
    user
    broadcast_message
    expires_at { 5.days.from_now }

    trait :expired do
      expires_at { 5.days.ago }
    end

    trait :future do
      expires_at { 5.days.from_now }
    end
  end
end
