# frozen_string_literal: true

FactoryBot.define do
  factory :ml_candidate_metadata, class: '::Ml::CandidateMetadata' do
    association :candidate, factory: :ml_candidates

    sequence(:name) { |n| "metadata_#{n}" }
    sequence(:value) { |n| "value#{n}" }
  end
end
