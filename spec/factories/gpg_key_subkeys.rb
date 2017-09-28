require_relative '../support/gpg_helpers'

FactoryGirl.define do
  factory :gpg_key_subkey do
    gpg_key

    keyid { gpg_key.subkeys.last.keyid }
    fingerprint { gpg_key.subkeys.last.fingerprint }
  end
end
