# frozen_string_literal: true

FactoryBot.define do
  factory :personal_access_token_last_used_ip, class: 'Authn::PersonalAccessTokenLastUsedIp' do
    personal_access_token
    organization { personal_access_token.organization }
    sequence(:ip_address) { |n| IPAddr.new(IPAddr.new('10.0.0.0').to_i + n, Socket::AF_INET) }
  end
end
