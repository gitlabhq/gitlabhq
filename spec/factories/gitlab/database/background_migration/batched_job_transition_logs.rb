# frozen_string_literal: true

FactoryBot.define do
  factory :batched_background_job_transition_log,
    class: '::Gitlab::Database::BackgroundMigration::BatchedJobTransitionLog' do
    batched_job factory: :batched_background_migration_job

    trait(:sidekiq_shutdown_failure) do
      previous_status { 1 }
      next_status { 2 }
      exception_class { 'Sidekiq::Shutdown' }
    end

    trait(:succeeded) do
      previous_status { 0 }
      next_status { 3 }
    end
  end
end
