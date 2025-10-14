# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_access_token_archived_record, class: 'Authn::OauthAccessTokenArchivedRecord' do
    sequence(:id)
    organization_id { create(:organization).id }
    token { Doorkeeper::OAuth::Helpers::UniqueToken.generate }
    refresh_token { Doorkeeper::OAuth::Helpers::UniqueToken.generate }
    scopes { 'read' }
    expires_in { 7200 }
    revoked_at { 1.month.ago }
    created_at { 2.months.ago }
    archived_at { Time.current }
  end
end
