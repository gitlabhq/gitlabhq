# frozen_string_literal: true

FactoryBot.define do
  factory :non_sql_service_ping, class: 'ServicePing::NonSqlServicePing' do
    recorded_at { Time.current }
    payload { { test: 'test' } }
    metadata { { name: 'test', time_elapsed: 100, error: nil } }
    association :organization, factory: :organization
  end
end
