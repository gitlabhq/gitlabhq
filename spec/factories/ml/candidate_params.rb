# frozen_string_literal: true

FactoryBot.define do
  factory :ml_candidate_params, class: '::Ml::CandidateParam' do
    association :candidate, factory: :ml_candidates

    sequence(:name) { |n| "params#{n}" }
    sequence(:value) { |n| "value#{n}" }
  end
end
