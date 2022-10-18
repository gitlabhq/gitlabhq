# frozen_string_literal: true

FactoryBot.define do
  factory :incident_management_timeline_event_tag, class: 'IncidentManagement::TimelineEventTag' do
    project
    name { 'Start time' }
  end
end
