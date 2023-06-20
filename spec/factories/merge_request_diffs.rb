# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff do
    association :merge_request, :skip_diff_creation
    state { :collected }
    commits_count { 1 }

    base_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    head_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    start_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }

    diff_type { :regular }

    trait :external do
      external_diff { fixture_file_upload("spec/fixtures/doc_sample.txt", "plain/txt") }
      stored_externally { true }
      importing { true } # this avoids setting the state to 'empty'
    end

    trait :merge_head do
      diff_type { :merge_head }
    end

    factory :external_merge_request_diff, traits: [:external]
  end
end
