# frozen_string_literal: true

FactoryBot.define do
  factory :ml_model_versions, class: '::Ml::ModelVersion' do
    sequence(:version) { |n| "1.0.#{n}-alpha+test" }

    model { association :ml_models }
    project { model.project }
    description { 'Some description' }

    candidate do
      association :ml_candidates, experiment: model.default_experiment, name: 'a_candidate', project: project,
        model_version: instance
    end

    trait :with_package do
      package do
        association :ml_model_package, name: model.name, version: version, project: project
      end
    end
  end
end
