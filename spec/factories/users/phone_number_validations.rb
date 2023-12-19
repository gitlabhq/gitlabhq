# frozen_string_literal: true

FactoryBot.define do
  factory :phone_number_validation, class: 'Users::PhoneNumberValidation' do
    user
    country { 'US' }
    international_dial_code { 1 }
    phone_number { '555' }
    telesign_reference_xid { FFaker::Guid.guid }

    trait(:validated) do
      validated_at { Time.zone.now }
    end
  end
end
