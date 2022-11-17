# frozen_string_literal: true

FactoryBot.define do
  factory :ci_secure_file, class: 'Ci::SecureFile' do
    sequence(:name) { |n| "file#{n}" }
    file { fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks', 'application/octet-stream') }
    checksum { 'foo1234' }
    project

    trait :remote_store do
      after(:create) do |ci_secure_file|
        ci_secure_file.update!(file_store: ObjectStorage::Store::REMOTE)
      end
    end
  end

  factory :ci_secure_file_with_metadata, class: 'Ci::SecureFile' do
    sequence(:name) { |n| "file#{n}.cer" }
    file { fixture_file_upload('spec/fixtures/ci_secure_files/sample.cer', 'application/octet-stream') }
    checksum { 'foo1234' }
    project

    after(:create, &:update_metadata!)
  end
end
