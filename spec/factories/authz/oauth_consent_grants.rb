# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_consent_grant, class: 'Authz::OauthConsentGrant' do
    user
    application
    source { :doorkeeper }

    transient do
      boundary { nil }
      permissions { nil }
    end

    oauth_consent_grant_granular_scopes do
      next [] unless permissions.present?

      granular_scope = association(:granular_scope,
        boundary: boundary, permissions: Array(permissions), strategy: :build)

      [association(:oauth_consent_grant_granular_scope,
        oauth_consent_grant: instance, granular_scope: granular_scope, strategy: :build)]
    end
  end
end
