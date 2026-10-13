# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_access_grant do
    resource_owner factory: :user
    application
    organization
    token { Doorkeeper::OAuth::Helpers::UniqueToken.generate }
    expires_in { 2.hours }

    redirect_uri { application.redirect_uri }
    scopes { application.scopes }
  end
end
