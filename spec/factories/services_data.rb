# frozen_string_literal: true

# these factories should never be called directly, they are used when creating services
FactoryBot.define do
  factory :jira_tracker_data do
    service
  end

  factory :issue_tracker_data do
    service
  end
end
