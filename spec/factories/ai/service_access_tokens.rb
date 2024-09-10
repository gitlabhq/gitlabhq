# frozen_string_literal: true

FactoryBot.define do
  factory :service_access_token, class: 'CloudConnector::ServiceAccessToken' do
    expires_at { 1.day.from_now }

    token do
      JWT.encode(
        {
          exp: expires_at.to_i,
          aud: ['example_audience'],
          iss: 'example_issuer',
          gitlab_realm: 'example_realm',
          scopes: ['example_scope']
        },
        nil,
        'none'
      )
    end

    trait :active do
      expires_at { 1.day.from_now }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :invalid do
      token { SecureRandom.alphanumeric(10) }
    end
  end
end
