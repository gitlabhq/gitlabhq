# frozen_string_literal: true

FactoryBot.define do
  factory :self_managed_prometheus_alert_event do
    project
    sequence(:payload_key) { |n| "hash payload key #{n}" }
    status { SelfManagedPrometheusAlertEvent.status_value_for(:firing) }
    title { 'alert' }
    query_expression { 'vector(2)' }
    started_at { Time.now }

    trait :resolved do
      status { SelfManagedPrometheusAlertEvent.status_value_for(:resolved) }
      ended_at { Time.now }
      payload_key { nil }
    end

    trait :none do
      status { nil }
      started_at { nil }
    end
  end
end
