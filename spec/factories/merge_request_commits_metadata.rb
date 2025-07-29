# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_commits_metadata, class: 'MergeRequest::CommitsMetadata' do
    association :project
    association :commit_author, factory: :merge_request_diff_commit_user
    association :committer, factory: :merge_request_diff_commit_user

    sha { OpenSSL::Digest::SHA256.hexdigest(SecureRandom.hex) }
    authored_date { Time.current }
    committed_date { Time.current }
  end
end
