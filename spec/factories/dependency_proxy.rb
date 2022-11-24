# frozen_string_literal: true

FactoryBot.define do
  factory :dependency_proxy_blob, class: 'DependencyProxy::Blob' do
    group
    size { 1234 }
    file_name { 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4.gz' }
    status { :default }

    after(:build) do |blob, _evaluator|
      blob.file = fixture_file_upload('spec/fixtures/dependency_proxy/a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4.gz')
    end

    trait :pending_destruction do
      status { :pending_destruction }
    end

    trait :remote_store do
      file_store { DependencyProxy::FileUploader::Store::REMOTE }
    end
  end

  factory :dependency_proxy_manifest, class: 'DependencyProxy::Manifest' do
    group
    size { 1234 }
    digest { 'sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515' }
    sequence(:file_name) { |n| "alpine:latest#{n}.json" }
    content_type { 'application/vnd.docker.distribution.manifest.v2+json' }
    status { :default }

    after(:build) do |manifest, _evaluator|
      manifest.file = fixture_file_upload('spec/fixtures/dependency_proxy/manifest')
    end

    trait :pending_destruction do
      status { :pending_destruction }
    end

    trait :remote_store do
      file_store { DependencyProxy::FileUploader::Store::REMOTE }
    end
  end
end
