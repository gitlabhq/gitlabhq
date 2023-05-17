# frozen_string_literal: true

FactoryBot.define do
  factory :project_error_tracking_setting, class: 'ErrorTracking::ProjectErrorTrackingSetting' do
    project
    api_url { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
    enabled { true }
    token { 'access_token_123' }
    project_name { 'Sentry Project' }
    organization_name { 'Sentry Org' }
    integrated { false }
    sentry_project_id { 10 }

    trait :disabled do
      enabled { false }
    end

    trait :integrated do
      api_url { nil }
      integrated { true }
      token { nil }
      project_name { nil }
      organization_name { nil }
      sentry_project_id { nil }
    end
  end
end
