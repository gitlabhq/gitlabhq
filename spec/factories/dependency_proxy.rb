# frozen_string_literal: true

FactoryBot.define do
  factory :dependency_proxy_blob, class: 'DependencyProxy::Blob' do
    group
    file { fixture_file_upload('spec/fixtures/dependency_proxy/a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4.gz') }
    file_name { 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4.gz' }
  end

  factory :dependency_proxy_manifest, class: 'DependencyProxy::Manifest' do
    group
    file { fixture_file_upload('spec/fixtures/dependency_proxy/manifest') }
    digest { 'sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515' }
    file_name { 'alpine:latest.json' }
    content_type { 'application/vnd.docker.distribution.manifest.v2+json' }
  end
end
