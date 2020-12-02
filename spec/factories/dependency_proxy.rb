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
    digest { 'sha256:5ab5a6872b264fe4fd35d63991b9b7d8425f4bc79e7cf4d563c10956581170c9' }
    file_name { 'manifest' }
  end
end
