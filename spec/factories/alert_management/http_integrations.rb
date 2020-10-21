# frozen_string_literal: true

FactoryBot.define do
  factory :alert_management_http_integration, class: 'AlertManagement::HttpIntegration' do
    project
    active { true }
    name { 'DataDog' }
    endpoint_identifier { SecureRandom.hex(4) }

    trait :inactive do
      active { false }
    end
  end
end
