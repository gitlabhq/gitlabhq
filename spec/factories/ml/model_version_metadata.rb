# frozen_string_literal: true

FactoryBot.define do
  factory :ml_model_version_metadata, class: '::Ml::ModelVersionMetadata' do
    association :model_version, factory: :ml_model_versions
    association :project, factory: :project

    sequence(:name) { |n| "metadata_#{n}" }
    sequence(:value) { |n| "value#{n}" }
  end
end
