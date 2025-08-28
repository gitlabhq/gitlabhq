# frozen_string_literal: true

FactoryBot.define do
  factory :personal_access_token_granular_scope, class: 'Authz::PersonalAccessTokenGranularScope' do
    organization
    personal_access_token
    granular_scope
  end
end
