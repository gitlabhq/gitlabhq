# frozen_string_literal: true
FactoryBot.define do
  factory :composer_cache_file, class: 'Packages::Composer::CacheFile' do
    group

    file_sha256 { '1' * 64 }

    transient do
      file_fixture { 'spec/fixtures/packages/composer/package.json' }
    end

    after(:build) do |cache_file, evaluator|
      cache_file.file = fixture_file_upload(evaluator.file_fixture)
    end

    trait(:object_storage) do
      file_store { Packages::Composer::CacheUploader::Store::REMOTE }
    end
  end
end
