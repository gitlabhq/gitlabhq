# frozen_string_literal: true

FactoryBot.define do
  factory :error_tracking_sentry_detailed_error, parent: :error_tracking_sentry_error, class: 'Gitlab::ErrorTracking::DetailedError' do
    gitlab_issue { 'http://gitlab.example.com/issues/1' }
    external_base_url { 'http://example.com' }
    first_release_last_commit { '68c914da9' }
    last_release_last_commit { '9ad419c86' }
    first_release_short_version { 'abc123' }
    last_release_short_version { 'abc123' }
    first_release_version { '12345678' }
    tags do
      {
        level: 'error',
        logger: 'rails'
      }
    end
    skip_create
  end
end
