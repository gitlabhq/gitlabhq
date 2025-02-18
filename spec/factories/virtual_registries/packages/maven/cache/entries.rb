# frozen_string_literal: true

FactoryBot.define do
  factory :virtual_registries_packages_maven_cache_entry,
    class: 'VirtualRegistries::Packages::Maven::Cache::Entry' do
    upstream { association :virtual_registries_packages_maven_upstream }
    group { upstream.group }
    sequence(:relative_path) { |n| "/a/relative/path/test-#{n}.txt" }
    size { 1.kilobyte }
    upstream_etag { OpenSSL::Digest.hexdigest('SHA256', 'test') }
    content_type { 'text/plain' }
    file_md5 { 'd8e8fca2dc0f896fd7cb4cb0031ba249' }
    file_sha1 { '4e1243bd22c66e76c2ba9eddc1f91394e57f9f83' }
    status { :default }

    transient do
      file_fixture { 'spec/fixtures/bfg_object_map.txt' }
    end

    after(:build) do |entry, evaluator|
      entry.upstream.registry_upstream.group = entry.group
      entry.file = fixture_file_upload(evaluator.file_fixture)
    end

    trait :upstream_checked do
      upstream_checked_at { 30.minutes.ago }
      upstream_etag { 'test' }
    end
  end
end
