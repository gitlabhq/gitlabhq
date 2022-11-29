# frozen_string_literal: true

FactoryBot.define do
  factory :ml_experiment_metadata, class: '::Ml::ExperimentMetadata' do
    association :experiment, factory: :ml_experiments

    sequence(:name) { |n| "metadata_#{n}" }
    sequence(:value) { |n| "value#{n}" }
  end
end
