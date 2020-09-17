# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff do
    merge_request do
      build(:merge_request) do |merge_request|
        # MergeRequest should not create a MergeRequestDiff in the callback
        allow(merge_request).to receive(:ensure_merge_request_diff)
      end
    end

    state { :collected }
    commits_count { 1 }

    base_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    head_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    start_commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }

    trait :external do
      external_diff { fixture_file_upload("spec/fixtures/doc_sample.txt", "plain/txt") }
      stored_externally { true }
      importing { true } # this avoids setting the state to 'empty'
    end

    factory :external_merge_request_diff, traits: [:external]
  end
end
