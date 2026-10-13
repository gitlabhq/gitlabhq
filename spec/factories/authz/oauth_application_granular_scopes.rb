# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application_granular_scope, class: 'Authz::OauthApplicationGranularScope' do
    application
    granular_scope
  end
end
