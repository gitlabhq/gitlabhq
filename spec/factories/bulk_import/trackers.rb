# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import_tracker, class: 'BulkImports::Tracker' do
    association :entity, factory: :bulk_import_entity

    stage { 0 }
    has_next_page { false }
    sequence(:pipeline_name) { |n| "pipeline_name_#{n}" }
    sequence(:jid) { |n| "bulk_import_entity_#{n}" }

    source_objects_count { 1 }
    fetched_objects_count { 1 }
    imported_objects_count { 1 }

    trait :started do
      status { 1 }
    end

    trait :finished do
      status { 2 }
    end

    trait :failed do
      status { -1 }
    end

    trait :skipped do
      status { -2 }
    end

    trait :batched do
      batched { true }
    end

    trait :canceled do
      status { -3 }
    end

    trait :stale do
      created_at { 1.day.ago }
    end
  end
end
