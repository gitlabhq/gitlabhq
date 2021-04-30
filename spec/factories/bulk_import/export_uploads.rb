# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import_export_upload, class: 'BulkImports::ExportUpload' do
    export { association(:bulk_import_export) }
  end
end
