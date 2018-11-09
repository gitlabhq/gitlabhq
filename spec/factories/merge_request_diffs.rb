# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff do
    association :merge_request
    state :collected
    commits_count 1

    base_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    head_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    start_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
  end
end
