# frozen_string_literal: true

FactoryBot.define do
  factory :rpm_repository_file, class: 'Packages::Rpm::RepositoryFile' do
    project

    file_name { '364c77dd49e8f814d56e621d0b3306c4fd0696dcad506f527329b818eb0f5db3-repomd.xml' }
    file_sha1 { 'efae869b4e95d54796a46481f3a211d6a88d0323' }
    file_md5 { 'ddf8a75330c896a8d7709e75f8b5982a' }
    file_sha256 { '364c77dd49e8f814d56e621d0b3306c4fd0696dcad506f527329b818eb0f5db3' }
    size { 3127.kilobytes }
    status { :default }

    transient do
      file_metadatum_trait { :xml }
    end

    transient do
      file_fixture do
        # rubocop:disable Layout/LineLength
        'spec/fixtures/packages/rpm/repodata/364c77dd49e8f814d56e621d0b3306c4fd0696dcad506f527329b818eb0f5db3-repomd.xml'
        # rubocop:enable Layout/LineLength
      end
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

    trait :filelists do
      file_name { 'filelists.xml' }
    end
  end
end
