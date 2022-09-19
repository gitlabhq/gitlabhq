# frozen_string_literal: true
FactoryBot.define do
  factory :ml_experiments, class: '::Ml::Experiment' do
    sequence(:name) { |n| "experiment#{n}" }
    association :project
    association :user
  end
end
