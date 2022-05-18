# frozen_string_literal: true
require 'ffaker'

FactoryBot.define do
  factory :alert_management_alert, class: 'AlertManagement::Alert' do
    triggered
    project
    title { FFaker::Lorem.sentence }
    started_at { Time.current }

    trait :with_validation_errors do
      after(:create) do |alert|
        too_many_hosts = Array.new(AlertManagement::Alert::HOSTS_MAX_LENGTH + 1) { |_| 'host' }
        alert.update_columns(hosts: too_many_hosts)
      end
    end

    trait :with_incident do
      after(:create) do |alert|
        create(:incident, alert_management_alert: alert, project: alert.project)
      end
    end

    trait :with_assignee do |alert|
      after(:create) do |alert|
        alert.alert_assignees.create!(assignee: create(:user))
      end
    end

    trait :with_fingerprint do
      fingerprint { SecureRandom.hex }
    end

    trait :with_service do
      service { FFaker::Product.product_name }
    end

    trait :with_monitoring_tool do
      monitoring_tool { FFaker::AWS.product_description }
    end

    trait :with_description do
      description { FFaker::Lorem.sentence }
    end

    trait :with_host do
      hosts { [FFaker::Internet.ip_v4_address] }
    end

    trait :without_ended_at do
      ended_at { nil }
    end

    trait :triggered do
      status { AlertManagement::Alert.status_value(:triggered) }
      without_ended_at
    end

    trait :acknowledged do
      status { AlertManagement::Alert.status_value(:acknowledged) }
      without_ended_at
    end

    trait :resolved do
      status { AlertManagement::Alert.status_value(:resolved) }
      ended_at { Time.current }
    end

    trait :ignored do
      status { AlertManagement::Alert.status_value(:ignored) }
      without_ended_at
    end

    trait :critical do
      severity { 'critical' }
    end

    trait :high do
      severity { 'high' }
    end

    trait :medium do
      severity { 'medium' }
    end

    trait :low do
      severity { 'low' }
    end

    trait :info do
      severity { 'info' }
    end

    trait :unknown do
      severity { 'unknown' }
    end

    trait :prometheus do
      monitoring_tool { Gitlab::AlertManagement::Payload::MONITORING_TOOLS[:prometheus] }
      payload do
        {
          annotations: {
            title: 'This is a prometheus error',
            summary: 'Summary of the error',
            description: 'Description of the error'
          },
          startsAt: started_at
        }.with_indifferent_access
      end
    end

    trait :all_fields do
      with_incident
      with_assignee
      with_fingerprint
      with_service
      with_monitoring_tool
      with_host
      with_description
      low
    end

    trait :from_payload do
      after(:build) do |alert|
        alert_params = ::Gitlab::AlertManagement::Payload.parse(
          alert.project,
          alert.payload,
          monitoring_tool: alert.monitoring_tool
        ).alert_params

        alert.assign_attributes(alert_params)
      end
    end
  end
end
