# frozen_string_literal: true

FactoryBot.define do
  factory :ml_model_metadata, class: '::Ml::ModelMetadata' do
    association :model, factory: :ml_models

    sequence(:name) { |n| "metadata_#{n}" }
    sequence(:value) { |n| "value#{n}" }
  end
end
