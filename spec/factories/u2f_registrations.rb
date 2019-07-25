# frozen_string_literal: true

FactoryBot.define do
  factory :u2f_registration do
    certificate { FFaker::BaconIpsum.characters(728) }
    key_handle { FFaker::BaconIpsum.characters(86) }
    public_key { FFaker::BaconIpsum.characters(88) }
    counter 0
  end
end
