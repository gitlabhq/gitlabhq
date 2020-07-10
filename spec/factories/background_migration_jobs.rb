# frozen_string_literal: true

FactoryBot.define do
  factory :background_migration_job, class: '::Gitlab::Database::BackgroundMigrationJob' do
    class_name { 'TestJob' }
    status { :pending }
    arguments { [] }

    trait :succeeded do
      status { :succeeded }
    end
  end
end
