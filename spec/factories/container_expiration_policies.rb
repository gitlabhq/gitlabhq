# frozen_string_literal: true

FactoryBot.define do
  factory :container_expiration_policy, class: 'ContainerExpirationPolicy' do
    association :project, factory: [:project, :without_container_expiration_policy]
    cadence { '1d' }
    enabled { true }

    trait :runnable do
      after(:create) do |policy|
        # next_run_at will be set before_save to Time.now + cadence, so this ensures the policy is active
        policy.update_column(:next_run_at, Time.zone.now - 1.day)
      end
    end

    trait :disabled do
      enabled { false }
    end
  end
end
