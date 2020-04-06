# frozen_string_literal: true

FactoryBot.define do
  factory :jira_import_state do
    project
    user { project&.creator }
    label
    jira_project_name { generate(:name) }
    jira_project_key { generate(:name) }
    jira_project_xid { 1234 }
  end

  trait :scheduled do
    status { :scheduled }
  end

  trait :started do
    status { :started }
  end

  trait :failed do
    status { :failed }
  end

  trait :finished do
    status { :finished }
  end
end
