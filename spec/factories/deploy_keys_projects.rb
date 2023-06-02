# frozen_string_literal: true

FactoryBot.define do
  factory :deploy_keys_project do
    deploy_key
    project

    trait :write_access do
      can_push { true }
    end

    trait :readonly_access do
      can_push { false }
    end
  end
end
