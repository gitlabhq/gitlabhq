# frozen_string_literal: true

FactoryBot.define do
  factory :jira_connect_installation do
    sequence(:client_key) { |n| "atlassian-client-key-#{n}" }
    shared_secret { 'jrNarHaRYaumMvfV3UnYpwt8' }
    base_url { 'https://sample.atlassian.net' }
    organization { association(:organization) }
    display_url { 'https://custom.example.com' }
  end
end
