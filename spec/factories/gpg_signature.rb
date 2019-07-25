# frozen_string_literal: true

FactoryBot.define do
  factory :gpg_signature do
    commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    project
    gpg_key
    gpg_key_primary_keyid { gpg_key.keyid }
    verification_status :verified
  end
end
