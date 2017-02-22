require_relative '../support/gpg_helpers'

FactoryGirl.define do
  factory :gpg_key do
    key GpgHelpers.public_key
  end
end
