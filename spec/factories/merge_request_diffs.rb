# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff do
    association :merge_request, factory: :merge_request_without_merge_request_diff
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
