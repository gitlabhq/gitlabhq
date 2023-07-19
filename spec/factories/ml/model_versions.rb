# frozen_string_literal: true

FactoryBot.define do
  factory :ml_model_versions, class: '::Ml::ModelVersion' do
    sequence(:version) { |n| "version#{n}" }

    model { association :ml_models }
    project { model.project }

    trait :with_package do
      package do
        association :ml_model_package, name: model.name, version: version, project_id: project.id
      end
    end
  end
end
