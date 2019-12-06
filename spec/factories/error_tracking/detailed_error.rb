# frozen_string_literal: true

FactoryBot.define do
  factory :detailed_error_tracking_error, class: Gitlab::ErrorTracking::DetailedError do
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
    external_base_url { 'http://example.com' }
    project_id { 'project1' }
    project_name { 'project name' }
    project_slug { 'project_name' }
    short_id { 'ID' }
    status { 'unresolved' }
    frequency do
      [
        [Time.now.to_i, 10]
      ]
    end
    first_release_last_commit { '68c914da9' }
    last_release_last_commit { '9ad419c86' }
    first_release_short_version { 'abc123' }
    last_release_short_version { 'abc123' }

    skip_create
  end
end
