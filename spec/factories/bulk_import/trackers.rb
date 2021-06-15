# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import_tracker, class: 'BulkImports::Tracker' do
    association :entity, factory: :bulk_import_entity

    stage { 0 }
    has_next_page { false }
    sequence(:pipeline_name) { |n| "pipeline_name_#{n}" }

    trait :started do
      status { 1 }

      sequence(:jid) { |n| "bulk_import_entity_#{n}" }
    end

    trait :finished do
      status { 2 }

      sequence(:jid) { |n| "bulk_import_entity_#{n}" }
    end

    trait :failed do
      status { -1 }

      sequence(:jid) { |n| "bulk_import_entity_#{n}" }
    end
  end
end
