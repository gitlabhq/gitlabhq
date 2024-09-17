# frozen_string_literal: true

FactoryBot.define do
  factory :issue_assignee do
    assignee { association(:user) }
    issue { association(:issue) }
  end
end
