# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_onboarding_action do
    namespace
    action { :subscription_created }
  end
end
