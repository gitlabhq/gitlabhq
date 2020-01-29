# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_context_commit_diff_file do
    association :merge_request_context_commit

    sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    relative_order { 0 }
    new_file { true }
    renamed_file { false }
    deleted_file { false }
    too_large { false }
    a_mode { 0 }
    b_mode { 100644 }
    new_path { 'foo' }
    old_path { 'foo' }
    diff { '' }
    binary { false }
  end
end
