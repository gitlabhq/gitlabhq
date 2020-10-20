# frozen_string_literal: true

FactoryBot.define do
  factory :csv_issue_import do
    project
    user
  end
end
