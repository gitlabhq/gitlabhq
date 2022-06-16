# frozen_string_literal: true

FactoryBot.define do
  factory :incident_management_timeline_event, class: 'IncidentManagement::TimelineEvent' do
    association :project
    association :author, factory: :user
    association :incident
    association :promoted_from_note, factory: :note
    occurred_at { Time.current }
    note { 'timeline created' }
    note_html { '<strong>timeline created</strong>' }
    action { 'comment' }
    editable
  end

  trait :editable do
    editable { true }
  end

  trait :non_editable do
    editable { false }
  end
end
