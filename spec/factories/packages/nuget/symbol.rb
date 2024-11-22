# frozen_string_literal: true

FactoryBot.define do
  factory :nuget_symbol, class: 'Packages::Nuget::Symbol' do
    package { association(:nuget_package) }
    file_path { 'lib/net7.0/package.pdb' }
    size { 100.bytes }
    sequence(:signature) { |n| "b91a152048fc4b3883bf3cf73fbc03f#{n}FFFFFFFF" }
    file_sha256 { 'dd1aaf26c557685cc37f93f53a2b6befb2c2e679f5ace6ec7a26d12086f358be' }
    project_id { package.project_id }
    status { :default }

    transient do
      file_fixture { 'spec/fixtures/packages/nuget/symbol/package.pdb' }
    end

    after(:build) do |symbol, evaluator|
      symbol.file = fixture_file_upload(evaluator.file_fixture)
    end

    trait :orphan do
      after(:create) do |entry|
        entry.update_attribute(:package_id, nil)
      end
    end

    trait :pending_destruction do
      default
      orphan
    end

    trait(:object_storage) do
      file_store { Packages::Nuget::SymbolUploader::Store::REMOTE }
    end
  end
end
