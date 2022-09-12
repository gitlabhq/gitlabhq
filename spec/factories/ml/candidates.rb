# frozen_string_literal: true
FactoryBot.define do
  factory :ml_candidates, class: '::Ml::Candidate' do
    association :experiment, factory: :ml_experiments
    association :user
  end
end
