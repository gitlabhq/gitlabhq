# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_access_token do
    resource_owner
    application
    organization
    token { Doorkeeper::OAuth::Helpers::UniqueToken.generate }
    refresh_token { Doorkeeper::OAuth::Helpers::UniqueToken.generate }
    scopes { application.scopes }
  end
end
