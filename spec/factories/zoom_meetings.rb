# frozen_string_literal: true

FactoryBot.define do
  factory :zoom_meeting do
    project { issue.project }
    issue
    url { 'https://zoom.us/j/123456789' }
    issue_status { :added }

    trait :added_to_issue do
      issue_status { :added }
    end

    trait :removed_from_issue do
      issue_status { :removed }
    end
  end
end
