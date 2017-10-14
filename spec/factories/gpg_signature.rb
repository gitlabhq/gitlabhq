require_relative '../support/gpg_helpers'

FactoryGirl.define do
  factory :gpg_signature do
    commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    project
    gpg_key
    gpg_key_primary_keyid { gpg_key.primary_keyid }
    verification_status :verified
  end
end
