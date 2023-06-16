# frozen_string_literal: true

FactoryBot.define do
  factory :error_tracking_open_api_error, class: 'ErrorTrackingOpenAPI::Error' do
    fingerprint { 1 }
    project_id { 2 }
    name { 'ActionView::MissingTemplate' }
    description { 'Missing template posts/edit' }
    actor { 'PostsController#edit' }
    event_count { 3 }
    approximated_user_count { 4 }
    first_seen_at { Time.now.iso8601 }
    last_seen_at { Time.now.iso8601 }
    status { 'unresolved' }
    stats do
      association(:error_tracking_open_api_error_stats)
    end

    skip_create
  end

  factory :error_tracking_open_api_error_stats, class: 'ErrorTrackingOpenAPI::ErrorStats' do
    frequency { { '24h': [[1, 2], [3, 4]] } }

    skip_create
  end

  factory :error_tracking_open_api_error_event, class: 'ErrorTrackingOpenAPI::ErrorEvent' do
    fingerprint { 1 }
    project_id { 2 }
    payload { File.read(Rails.root.join('spec/fixtures/error_tracking/parsed_event.json')) }
    name { 'ActionView::MissingTemplate' }
    description { 'Missing template posts/edit' }
    actor { 'PostsController#edit' }
    environment { 'development' }
    platform { 'ruby' }

    trait :golang do
      payload { File.read(Rails.root.join('spec/fixtures/error_tracking/go_parsed_event.json')) }
      platform { 'go' }
    end

    trait :browser do
      payload { File.read(Rails.root.join('spec/fixtures/error_tracking/browser_event.json')) }
      platform { 'javascript' }
    end

    skip_create
  end
end
