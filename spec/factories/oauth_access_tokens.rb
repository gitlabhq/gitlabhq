# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_access_token do
    resource_owner
    application
    token { Doorkeeper::OAuth::Helpers::UniqueToken.generate }
    scopes { application.scopes }
  end
end
