# frozen_string_literal: true

require_relative '../support/helpers/gpg_helpers'

FactoryBot.define do
  factory :gpg_key do
    key { GpgHelpers::User1.public_key }
    user

    factory :gpg_key_with_subkeys do
      key { GpgHelpers::User1.public_key_with_extra_signing_key }
    end

    factory :another_gpg_key do
      key { GpgHelpers::User1.public_key2 }
      user
    end
  end
end
