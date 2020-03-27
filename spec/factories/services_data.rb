# frozen_string_literal: true

# these factories should never be called directly, they are used when creating services
FactoryBot.define do
  factory :jira_tracker_data do
    service
  end

  factory :issue_tracker_data do
    service
  end

  factory :open_project_tracker_data do
    service
    url { 'http://openproject.example.com'}
    token { 'supersecret' }
    project_identifier_code { 'PRJ-1' }
    closed_status_id { '15' }
  end
end
