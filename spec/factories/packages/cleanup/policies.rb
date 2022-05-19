# frozen_string_literal: true

FactoryBot.define do
  factory :packages_cleanup_policy, class: 'Packages::Cleanup::Policy' do
    project

    keep_n_duplicated_package_files { '10' }

    trait :runnable do
      after(:create) do |policy|
        # next_run_at will be set before_save to Time.now + cadence, so this ensures the policy is active
        policy.update_column(:next_run_at, Time.zone.now - 1.day)
      end
    end
  end
end
