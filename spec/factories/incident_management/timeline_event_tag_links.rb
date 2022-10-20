# frozen_string_literal: true

FactoryBot.define do
  factory :incident_management_timeline_event_tag_link, class: 'IncidentManagement::TimelineEventTagLink' do
    association :timeline_event_tag, factory: :incident_management_timeline_event_tag
    association :timeline_event, factory: :incident_management_timeline_event
  end
end
