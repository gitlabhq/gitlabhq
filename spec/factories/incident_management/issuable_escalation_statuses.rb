# frozen_string_literal: true

FactoryBot.define do
  factory :incident_management_issuable_escalation_status, class: 'IncidentManagement::IssuableEscalationStatus' do
    association :issue, factory: :incident
    triggered

    trait :triggered do
      status { ::IncidentManagement::IssuableEscalationStatus.status_value(:triggered) }
    end

    trait :acknowledged do
      status { ::IncidentManagement::IssuableEscalationStatus.status_value(:acknowledged) }
    end

    trait :resolved do
      status { ::IncidentManagement::IssuableEscalationStatus.status_value(:resolved) }
      resolved_at { Time.current }
    end

    trait :ignored do
      status { ::IncidentManagement::IssuableEscalationStatus.status_value(:ignored) }
    end
  end
end
