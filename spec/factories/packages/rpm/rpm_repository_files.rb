# frozen_string_literal: true

FactoryBot.define do
  factory :rpm_repository_file, class: 'Packages::Rpm::RepositoryFile' do
    project

    file_name { 'repomd.xml' }
    file_sha1 { 'efae869b4e95d54796a46481f3a211d6a88d0323' }
    file_md5 { 'ddf8a75330c896a8d7709e75f8b5982a' }
    size { 3127.kilobytes }
    status { :default }

    transient do
      file_metadatum_trait { :xml }
    end

    transient do
      file_fixture { 'spec/fixtures/packages/rpm/repodata/repomd.xml' }
    end

    after(:build) do |package_file, evaluator|
      package_file.file = fixture_file_upload(evaluator.file_fixture)
    end

    trait(:object_storage) do
      file_store { Packages::Rpm::RepositoryFileUploader::Store::REMOTE }
    end

    trait :pending_destruction do
      status { :pending_destruction }
    end
  end
end
