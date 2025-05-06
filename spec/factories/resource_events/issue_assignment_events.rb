# frozen_string_literal: true

FactoryBot.define do
  factory :issue_assignment_event, class: 'ResourceEvents::IssueAssignmentEvent' do
    action { :add }
    issue
    user
  end
end
