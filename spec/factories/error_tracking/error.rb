# frozen_string_literal: true

FactoryBot.define do
  factory :error_tracking_error, class: 'Gitlab::ErrorTracking::Error' do
    id { 'id' }
    title { 'title' }
    type { 'error' }
    user_count { 1 }
    count { 2 }
    first_seen { Time.now }
    last_seen { Time.now }
    message { 'message' }
    culprit { 'culprit' }
    external_url { 'http://example.com/id' }
    project_id { 'project1' }
    project_name { 'project name' }
    project_slug { 'project_name' }
    short_id { 'ID' }
    status { 'unresolved' }
    frequency { [] }

    skip_create
  end
end
