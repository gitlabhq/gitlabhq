# frozen_string_literal: true

FactoryBot.define do
  factory :queries_service_ping, class: 'ServicePing::QueriesServicePing' do
    recorded_at { Time.current }
    payload { { test: 'test' } }
    association :organization, factory: :organization
  end
end
