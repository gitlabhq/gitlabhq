# frozen_string_literal: true

FactoryBot.define do
  factory :relation_export_upload, class: 'Projects::ImportExport::RelationExportUpload' do
    relation_export factory: :project_relation_export
    export_file { fixture_file_upload("spec/fixtures/gitlab/import_export/labels.tar.gz") }
  end
end
