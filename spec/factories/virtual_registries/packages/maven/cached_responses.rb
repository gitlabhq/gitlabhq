# frozen_string_literal: true

FactoryBot.define do
  factory :virtual_registries_packages_maven_cached_response,
    class: 'VirtualRegistries::Packages::Maven::CachedResponse' do
    upstream { association :virtual_registries_packages_maven_upstream }
    group { upstream.group }
    relative_path { |n| "/a/relative/path/test-#{n}.txt" }
    size { 1.kilobyte }
    upstream_etag { OpenSSL::Digest.hexdigest('SHA256', 'test') }
    content_type { 'text/plain' }
    downloads_count { 5 }

    transient do
      file_fixture { 'spec/fixtures/bfg_object_map.txt' }
    end

    after(:build) do |entry, evaluator|
      entry.upstream.registry_upstream.group = entry.group
      entry.file = fixture_file_upload(evaluator.file_fixture)
    end
  end
end
