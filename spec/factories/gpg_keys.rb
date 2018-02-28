require_relative '../support/gpg_helpers'

FactoryGirl.define do
  factory :gpg_key do
    key GpgHelpers::User1.public_key
    user
  end
end
