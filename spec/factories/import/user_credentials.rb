# frozen_string_literal: true

FactoryBot.define do
  factory :import_user_credential, class: 'Import::UserCredential' do
    user
    provider { :github }
    provider_host { 'github.com' }
    sequence(:provider_account_xid)
    sequence(:access_token) { |n| "gho_token#{n}" }
    scopes { 'repo,read:org' }
  end
end
