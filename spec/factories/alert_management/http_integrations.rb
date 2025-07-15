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

    trait :active do
      active { true }
    end

    trait :legacy do
      endpoint_identifier { 'legacy' }
    end

    initialize_with { new(**attributes) }

    trait :prometheus do
      type_identifier { :prometheus }
    end

    factory :alert_management_prometheus_integration, traits: [:prometheus] do
      type_identifier { :prometheus }

      trait :legacy do
        name { 'Prometheus' }
        endpoint_identifier { 'legacy-prometheus' }
      end
    end
  end
end
