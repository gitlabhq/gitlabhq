# frozen_string_literal: true

FactoryBot.define do
  # There is an issue to rename this class https://gitlab.com/gitlab-org/gitlab/-/issues/323342.
  factory :early_access_program_tracking_event, class: 'EarlyAccessProgram::TrackingEvent' do
    user
    event_name { 'g_edit_by_snippet_ide' }
    event_label { 'event_label' }
    category { 'Mutations::Snippets::Create' }
  end
end
