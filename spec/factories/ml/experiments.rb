# frozen_string_literal: true
FactoryBot.define do
  factory :ml_experiments, class: '::Ml::Experiment' do
    sequence(:name) { |n| "experiment#{n}" }

    project
    user { project&.creator }

    after(:stub) do |record|
      record.iid ||= generate(:iid)
    end

    trait :with_metadata do
      after(:create) do |e|
        e.metadata = FactoryBot.create_list(:ml_experiment_metadata, 2, experiment: e) # rubocop:disable StrategyInCallback
      end
    end

    trait :with_candidates do
      candidates do
        Array.new(2) do
          association(:ml_candidates, project: project)
        end
      end
    end

    trait :with_model do
      association :model, factory: :ml_models
    end
  end
end
