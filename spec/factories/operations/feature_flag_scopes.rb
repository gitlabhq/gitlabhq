# frozen_string_literal: true

FactoryBot.define do
  factory :operations_feature_flag_scope, class: 'Operations::FeatureFlagScope' do
    association :feature_flag, factory: [:operations_feature_flag, :legacy_flag]
    active { true }
    strategies { [{ name: "default", parameters: {} }] }
    sequence(:environment_scope) { |n| "review/patch-#{n}" }
  end
end
