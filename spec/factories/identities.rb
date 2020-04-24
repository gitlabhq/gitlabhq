# frozen_string_literal: true

FactoryBot.define do
  factory :identity do
    provider { 'ldapmain' }
    sequence(:extern_uid) { |n| "my-ldap-id-#{n}" }
  end
end
