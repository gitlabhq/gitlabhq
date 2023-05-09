# frozen_string_literal: true

FactoryBot.define do
  factory :npm_metadata_cache, class: 'Packages::Npm::MetadataCache' do
    project
    sequence(:package_name) { |n| "@#{project.root_namespace.path}/package-#{n}" }
    file { fixture_file_upload('spec/fixtures/packages/npm/metadata.json') }
    size { 401.bytes }
  end
end
