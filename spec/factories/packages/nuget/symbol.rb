# frozen_string_literal: true

FactoryBot.define do
  factory :nuget_symbol, class: 'Packages::Nuget::Symbol' do
    package { association(:nuget_package) }
    file { fixture_file_upload('spec/fixtures/packages/nuget/symbol/package.pdb') }
    file_path { 'lib/net7.0/package.pdb' }
    size { 100.bytes }
    sequence(:signature) { |n| "b91a152048fc4b3883bf3cf73fbc03f#{n}FFFFFFFF" }
    file_sha256 { 'dd1aaf26c557685cc37f93f53a2b6befb2c2e679f5ace6ec7a26d12086f358be' }

    trait :stale do
      after(:create) do |entry|
        entry.update_attribute(:package_id, nil)
      end
    end
  end
end
