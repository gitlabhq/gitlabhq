# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_assignment_event, class: 'ResourceEvents::MergeRequestAssignmentEvent' do
    action { :add }
    merge_request
    user
  end
end
