# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_consent, class: 'Authn::OauthConsent' do
    user
    application factory: :oauth_application
    client_id { application.uid }
    consent_challenge { SecureRandom.hex(32) }
    requested_scopes { %w[openid profile] }

    trait :revoked do
      status { :revoked }
    end
  end
end
