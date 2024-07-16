# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_instance_audit_event, class: 'AuditEvents::InstanceAuditEvent' do
    user

    entity_path { "gitlab_instance" }
    target_details { "Default project visibility" }
    ip_address { IPAddr.new '127.0.0.1' }
    author_name { 'Jane Doe' }
    details do
      {
        change: "default_project_visibility",
        from: 0,
        to: 10,
        target_details: "Default project visibility",
        event_name: "application_setting_updated",
        author_name: 'Jane Doe',
        target_id: 1,
        target_type: "ApplicationSetting",
        custom_message: "Changed default_project_visibility from 0 to 10",
        ip_address: "127.0.0.1",
        entity_path: "gitlab_instance"
      }
    end
  end
end
