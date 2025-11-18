# frozen_string_literal: true

FactoryBot.define do
  factory :webauthn_registration do
    credential_xid { SecureRandom.base64(88) }
    public_key { SecureRandom.base64(103) }
    name { FFaker::BaconIpsum.characters(10) }
    counter { 1 }
    user

    trait :passkey do
      authentication_mode { :passwordless }
      passkey_eligible { true }
    end

    trait :second_factor do
      authentication_mode { :second_factor }
    end

    trait :passkey_eligible do
      authentication_mode { :second_factor }
      passkey_eligible { true }
    end
  end
end
