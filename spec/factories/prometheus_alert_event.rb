# frozen_string_literal: true

FactoryBot.define do
  factory :prometheus_alert_event do
    project { prometheus_alert.project }
    prometheus_alert
    sequence(:payload_key) { |n| "hash payload key #{n}" }
    status { PrometheusAlertEvent.status_value_for(:firing) }
    started_at { Time.now }

    trait :resolved do
      status { PrometheusAlertEvent.status_value_for(:resolved) }
      ended_at { Time.now }
      payload_key { nil }
    end
  end
end
