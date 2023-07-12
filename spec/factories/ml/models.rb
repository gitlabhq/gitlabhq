# frozen_string_literal: true

FactoryBot.define do
  factory :ml_models, class: '::Ml::Model' do
    sequence(:name) { |n| "model#{n}" }

    project
    default_experiment { association :ml_experiments, project_id: project.id, name: name }
  end
end
