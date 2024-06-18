# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import_batch_tracker, class: 'BulkImports::BatchTracker' do
    association :tracker, factory: :bulk_import_tracker

    status { 0 }
    fetched_objects_count { 1000 }
    imported_objects_count { 1000 }

    sequence(:batch_number) { |n| n }

    trait :created do
      status { 0 }
    end

    trait :started do
      status { 1 }
    end

    trait :finished do
      status { 2 }
    end

    trait :timeout do
      status { 3 }
    end

    trait :failed do
      status { -1 }
    end

    trait :skipped do
      status { -2 }
    end

    trait :canceled do
      status { -3 }
    end
  end
end
