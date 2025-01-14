# frozen_string_literal: true

FactoryBot.define do
  factory :personal_access_token_last_used_ip, class: 'Authn::PersonalAccessTokenLastUsedIp' do
    personal_access_token
    ip_address { IPAddr.new('42.43.44.45') }
  end
end
