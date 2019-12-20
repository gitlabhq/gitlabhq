# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_openid_request, class: 'Doorkeeper::OpenidConnect::Request' do
    access_grant factory: :oauth_access_grant
    sequence(:nonce) { |n| n.to_s }
  end
end
