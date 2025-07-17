# frozen_string_literal: true

FactoryBot.define do
  factory :helm_metadata_cache, class: 'Packages::Helm::MetadataCache' do
    project
    size { 401.bytes }
    status { :default }
    sequence(:channel) { |n| "#{FFaker::Lorem.word}-#{n}" }

    transient do
      file_fixture { 'spec/fixtures/packages/helm/index.yaml' }
    end

    after(:build) do |entry, evaluator|
      entry.file = fixture_file_upload(evaluator.file_fixture)
    end

    trait(:object_storage) do
      file_store { Packages::Helm::MetadataCacheUploader::Store::REMOTE }
    end
  end
end
