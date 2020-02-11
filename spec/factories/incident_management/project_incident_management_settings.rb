# frozen_string_literal: true

FactoryBot.define do
  factory :project_incident_management_setting, class: 'IncidentManagement::ProjectIncidentManagementSetting' do
    project
    create_issue { false }
    issue_template_key { nil }
    send_email { false }
  end
end
