# frozen_string_literal: true

FactoryBot.define do
  factory :detailed_error_tracking_error, class: Gitlab::ErrorTracking::DetailedError do
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
    external_base_url { 'http://example.com' }
    project_id { 'project1' }
    project_name { 'project name' }
    project_slug { 'project_name' }
    short_id { 'ID' }
    status { 'unresolved' }
    frequency { [] }
    first_release_last_commit { '68c914da9' }
    last_release_last_commit { '9ad419c86' }
    first_release_short_version { 'abc123' }
    last_release_short_version { 'abc123' }

    skip_create
  end
end
