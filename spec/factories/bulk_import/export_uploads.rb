# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import_export_upload, class: 'BulkImports::ExportUpload' do
    export { association(:bulk_import_export) }

    trait :with_export_file do
      export_file { fixture_file_upload('spec/fixtures/bulk_imports/gz/labels.ndjson.gz') }
    end

    transient do
      group { nil }
    end

    after(:build) do |export_upload, evaluator|
      export_upload.group_id = evaluator.group.id if evaluator.group
    end
  end
end
