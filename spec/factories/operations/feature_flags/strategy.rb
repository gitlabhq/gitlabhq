# frozen_string_literal: true

FactoryBot.define do
  factory :operations_strategy, class: 'Operations::FeatureFlags::Strategy' do
    association :feature_flag, factory: :operations_feature_flag
    name { "default" }
    parameters { {} }
  end
end
