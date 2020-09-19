# frozen_string_literal: true

FactoryBot.define do
  factory :webauthn_registration do
    credential_xid { SecureRandom.base64(88) }
    public_key { SecureRandom.base64(103) }
    name { FFaker::BaconIpsum.characters(10) }
    counter { 1 }
    user
  end
end
