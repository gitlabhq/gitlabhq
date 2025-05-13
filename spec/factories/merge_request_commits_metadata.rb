# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_commits_metadata, class: 'MergeRequest::CommitsMetadata' do
    association :project

    sha { OpenSSL::Digest::SHA256.hexdigest(SecureRandom.hex) }
  end
end
