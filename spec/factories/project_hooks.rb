# frozen_string_literal: true

FactoryBot.define do
  factory :project_hook do
    url { generate(:url) }
    name { generate(:name) }
    description { "Description of #{name}" }
    enable_ssl_verification { false }
    project

    trait :url_variables do
      url_variables { { 'abc' => 'supers3cret', 'def' => 'foobar' } }
    end

    trait :token do
      token { generate(:token) }
    end

    trait :all_events_enabled do
      push_events { true }
      merge_requests_events { true }
      tag_push_events { true }
      issues_events { true }
      confidential_issues_events { true }
      note_events { true }
      confidential_note_events { true }
      job_events { true }
      pipeline_events { true }
      wiki_page_events { true }
      deployment_events { true }
      feature_flag_events { true }
      releases_events { true }
      emoji_events { true }
      vulnerability_events { true }
    end

    trait :with_push_branch_filter do
      push_events_branch_filter { 'my-branch-*' }
    end

    trait :permanently_disabled do
      recent_failures { WebHooks::AutoDisabling::FAILURE_THRESHOLD + 1 }
    end
  end
end
