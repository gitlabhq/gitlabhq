# frozen_string_literal: true

FactoryBot.define do
  factory :merge_requests_risk_outcome, class: 'MergeRequests::RiskOutcome' do
    association :risk_assessment, factory: :merge_requests_risk_assessment
    project_id { risk_assessment.project_id }
    signal_type { 0 }
    observed_at { Time.current }
    confidence { 0 }
  end
end
