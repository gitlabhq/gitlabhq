# frozen_string_literal: true

FactoryBot.define do
  factory :project_error_tracking_setting, class: ErrorTracking::ProjectErrorTrackingSetting do
    project
    api_url 'https://gitlab.com'
    enabled true
    token 'access_token_123'
  end
end
