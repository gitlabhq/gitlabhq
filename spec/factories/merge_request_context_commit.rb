# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_context_commit do
    association :merge_request, factory: :merge_request
    author_name { 'test' }
    author_email { 'test@test.com' }
    message { '' }
    relative_order { 0 }
    sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
  end
end
