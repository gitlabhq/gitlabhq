# frozen_string_literal: true

FactoryBot.define do
  factory :error_tracking_client_key, class: 'ErrorTracking::ClientKey' do
    project
    active { true }

    trait :disabled do
      active { false }
    end
  end
end
