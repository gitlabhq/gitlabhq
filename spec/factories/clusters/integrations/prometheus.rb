# frozen_string_literal: true

FactoryBot.define do
  factory :clusters_integrations_prometheus, class: 'Clusters::Integrations::Prometheus' do
    cluster factory: %i[cluster provided_by_gcp]
    enabled { true }

    trait :disabled do
      enabled { false }
    end
  end
end
