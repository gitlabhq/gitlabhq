# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_consent_grant_granular_scope, class: 'Authz::OauthConsentGrantGranularScope' do
    oauth_consent_grant
    granular_scope
  end
end
