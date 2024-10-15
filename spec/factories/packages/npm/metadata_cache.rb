# frozen_string_literal: true

FactoryBot.define do
  factory :npm_metadata_cache, class: 'Packages::Npm::MetadataCache' do
    project
    sequence(:package_name) { |n| "@#{project.root_namespace.path}/package-#{n}" }
    size { 401.bytes }
    status { :default }

    transient do
      file_fixture { 'spec/fixtures/packages/npm/metadata.json' }
    end

    after(:build) do |entry, evaluator|
      entry.file = fixture_file_upload(evaluator.file_fixture)
    end

    trait(:object_storage) do
      file_store { Packages::Npm::MetadataCacheUploader::Store::REMOTE }
    end
  end
end
