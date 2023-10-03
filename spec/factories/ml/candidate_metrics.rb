# frozen_string_literal: true

FactoryBot.define do
  factory :ml_candidate_metrics, class: '::Ml::CandidateMetric' do
    association :candidate, factory: :ml_candidates

    sequence(:name) { |n| "metric#{n}" }
    value { 2.0 }
    step { 0 }
    tracked_at { 1234 }
  end
end
