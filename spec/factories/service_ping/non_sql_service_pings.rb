# frozen_string_literal: true

FactoryBot.define do
  factory :non_sql_service_ping, class: 'ServicePing::NonSqlServicePing' do
    recorded_at { Time.current }
    payload { { test: 'test' } }
    association :organization, factory: :organization
  end
end
