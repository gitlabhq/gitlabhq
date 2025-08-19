# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_generated_ref_commit, class: 'MergeRequests::GeneratedRefCommit' do
    commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) } # rubocop:disable Fips/SHA1 -- test data
    association :project
    association :merge_request
  end
end
