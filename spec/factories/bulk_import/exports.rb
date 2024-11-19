# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import_export, class: 'BulkImports::Export', traits: %i[started] do
    group { association(:group) if project.nil? }
    relation { 'labels' }

    trait :started do
      status { 0 }

      sequence(:jid) { |n| "bulk_import_export_#{n}" }
    end

    trait :finished do
      status { 1 }

      sequence(:jid) { |n| "bulk_import_export_#{n}" }
    end

    trait :failed do
      status { -1 }
    end

    trait :batched do
      batched { true }
    end
  end
end
