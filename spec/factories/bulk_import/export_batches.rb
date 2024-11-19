# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import_export_batch, class: 'BulkImports::ExportBatch' do
    association :export, factory: :bulk_import_export

    upload { association(:bulk_import_export_upload) }

    status { 0 }
    batch_number { 1 }

    trait :created do
      status { 0 }
    end

    trait :finished do
      status { 1 }
    end

    trait :started do
      status { 2 }
    end

    trait :failed do
      status { -1 }
    end
  end
end
