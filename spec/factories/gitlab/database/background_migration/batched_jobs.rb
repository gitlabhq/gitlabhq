# frozen_string_literal: true

FactoryBot.define do
  factory :batched_background_migration_job, class: '::Gitlab::Database::BackgroundMigration::BatchedJob' do
    batched_migration factory: :batched_background_migration

    min_value { 1 }
    max_value { 10 }
    batch_size { 5 }
    sub_batch_size { 1 }
    pause_ms { 100 }

    trait(:pending) do
      status { 0 }
    end

    trait(:running) do
      status { 1 }
    end

    trait(:failed) do
      status { 2 }
    end

    trait(:succeeded) do
      status { 3 }
    end
  end
end
