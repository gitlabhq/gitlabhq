require_relative '../support/gpg_helpers'

FactoryBot.define do
  factory :gpg_key do
    key GpgHelpers::User1.public_key
    user

    factory :gpg_key_with_subkeys do
      key GpgHelpers::User1.public_key_with_extra_signing_key
    end
  end
end
