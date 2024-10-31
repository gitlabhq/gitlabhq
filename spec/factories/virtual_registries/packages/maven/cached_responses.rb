# frozen_string_literal: true

FactoryBot.define do
  factory :virtual_registries_packages_maven_cached_response,
    class: 'VirtualRegistries::Packages::Maven::CachedResponse' do
    upstream { association :virtual_registries_packages_maven_upstream }
    group { upstream.group }
    sequence(:relative_path) { |n| "/a/relative/path/test-#{n}.txt" }
    size { 1.kilobyte }
    upstream_etag { OpenSSL::Digest.hexdigest('SHA256', 'test') }
    content_type { 'text/plain' }
    file_final_path { '5f/9c/5f9c/@final/c7/4c/240c' }
    file_md5 { '54ce07f4124259b2ea58548e9d620004' }
    file_sha1 { 'bbde7c9fb6d74f9a2393bb36b0d4ac7e72c227ee' }
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
