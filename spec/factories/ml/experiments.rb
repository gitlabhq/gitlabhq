# frozen_string_literal: true
FactoryBot.define do
  factory :ml_experiments, class: '::Ml::Experiment' do
    sequence(:name) { |n| "experiment#{n}" }

    project
    user { project&.creator }

    trait :with_metadata do
      after(:create) do |e|
        e.metadata = FactoryBot.create_list(:ml_experiment_metadata, 2, experiment: e) # rubocop:disable StrategyInCallback
      end
    end
  end
end
