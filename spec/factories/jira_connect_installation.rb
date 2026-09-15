# frozen_string_literal: true

FactoryBot.define do
  factory :jira_connect_installation do
    sequence(:client_key) { |n| "atlassian-client-key-#{n}" }
    shared_secret { 'jrNarHaRYaumMvfV3UnYpwt8' }
    base_url { 'https://sample.atlassian.net' }
    organization { association(:common_organization) }
    display_url { 'https://custom.example.com' }

    # A native Forge install: a Forge installation id, site cloud_id and
    # system-token context, but no Connect credentials.
    trait :forge do
      client_key { nil }
      shared_secret { nil }
      base_url { nil }
      display_url { nil }
      forge_installation_xid { "ari:cloud:ecosystem::installation/#{SecureRandom.uuid}" }
      sequence(:cloud_id) { |n| "cloud-#{n}" }
      jira_api_base_url { 'https://api.atlassian.com/ex/jira/cloud-xyz' }
      forge_system_token { 'sys-token' }
    end
  end
end
