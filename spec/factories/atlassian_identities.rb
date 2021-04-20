# frozen_string_literal: true

FactoryBot.define do
  factory :atlassian_identity, class: 'Atlassian::Identity' do
    extern_uid { generate(:username) }
    user { association(:user) }
    expires_at { 2.weeks.from_now }
    token { SecureRandom.alphanumeric(1254) }
    refresh_token { SecureRandom.alphanumeric(45) }
  end
end
