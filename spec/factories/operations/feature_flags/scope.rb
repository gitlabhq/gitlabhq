# frozen_string_literal: true

FactoryBot.define do
  factory :operations_scope, class: 'Operations::FeatureFlags::Scope' do
    association :strategy, factory: :operations_strategy
    sequence(:environment_scope) { |n| "review/patch-#{n}" }
  end
end
