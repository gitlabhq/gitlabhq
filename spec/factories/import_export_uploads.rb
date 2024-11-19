# frozen_string_literal: true

FactoryBot.define do
  factory :import_export_upload do
    project { association(:project) if group.nil? }
    user { association(:user) }
    export_file { fixture_file_upload('spec/fixtures/group_export.tar.gz') }
  end
end
