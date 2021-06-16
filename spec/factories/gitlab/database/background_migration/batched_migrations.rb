# frozen_string_literal: true

FactoryBot.define do
  factory :batched_background_migration, class: '::Gitlab::Database::BackgroundMigration::BatchedMigration' do
    max_value { 10 }
    batch_size { 5 }
    sub_batch_size { 1 }
    interval { 2.minutes }
    job_class_name { 'CopyColumnUsingBackgroundMigrationJob' }
    table_name { :events }
    column_name { :id }
    sequence(:job_arguments) { |n| [["column_#{n}"], ["column_#{n}_convert_to_bigint"]] }
    total_tuple_count { 10_000 }
    pause_ms { 100 }
  end
end
