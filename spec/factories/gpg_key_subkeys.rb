require_relative '../support/gpg_helpers'

FactoryBot.define do
  factory :gpg_key_subkey do
    gpg_key

    sequence(:keyid) { |n| "keyid-#{n}" }
    sequence(:fingerprint) { |n| "fingerprint-#{n}" }
  end
end
