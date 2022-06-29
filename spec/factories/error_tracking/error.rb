# frozen_string_literal: true

FactoryBot.define do
  # There is an issue to rename this class https://gitlab.com/gitlab-org/gitlab/-/issues/323342.
  factory :error_tracking_sentry_error, class: 'Gitlab::ErrorTracking::Error' do
    id { '1' }
    title { 'title' }
    type { 'error' }
    user_count { 1 }
    count { 2 }
    first_seen { Time.now.iso8601 }
    last_seen { Time.now.iso8601 }
    message { 'message' }
    culprit { 'culprit' }
    external_url { 'http://example.com/id' }
    project_id { '111111' }
    project_name { 'project name' }
    project_slug { 'project_name' }
    short_id { 'ID' }
    status { 'unresolved' }
    frequency do
      [
        [Time.now.to_i, 10]
      ]
    end

    skip_create
  end

  factory :error_tracking_error, class: 'ErrorTracking::Error' do
    project
    name { 'ActionView::MissingTemplate' }
    description { 'Missing template posts/edit' }
    actor { 'PostsController#edit' }
    platform { 'ruby' }
    first_seen_at { Time.now.iso8601 }
    last_seen_at { Time.now.iso8601 }
    status { 'unresolved' }

    trait :resolved do
      status { 'resolved' }
    end
  end
end
