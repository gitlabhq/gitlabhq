# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff_commit do
    association :merge_request_diff

    sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    relative_order { 0 }
  end
end
