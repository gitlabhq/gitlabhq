# frozen_string_literal: true

FactoryBot.define do
  factory :ci_secure_file, class: 'Ci::SecureFile' do
    name { 'filename' }
    file { fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks', 'application/octet-stream') }
    checksum { 'foo1234' }
    project
  end
end
