# frozen_string_literal: true

FactoryBot.define do
  factory :container_expiration_policy, class: 'ContainerExpirationPolicy' do
    # Note: because of the project_id primary_key on
    # container_expiration_policies, and the create_container_expiration_policy
    # callback on Project, we need to build the project first before assigning
    # it to a container_expiration_policy.
    #
    # Also, if you wish to assign an existing project to a
    # container_expiration_policy, you will then have to destroy the project's
    # container_expiration_policy first.
    before(:create) do |container_expiration_policy|
      container_expiration_policy.project = build(:project) unless container_expiration_policy.project
    end

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
