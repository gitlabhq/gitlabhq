# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_consent_grant, class: 'Authz::OauthConsentGrant' do
    user
    application
    source { :doorkeeper }
  end
end
