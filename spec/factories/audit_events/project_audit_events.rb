# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_project_audit_event, class: 'AuditEvents::ProjectAuditEvent' do
    user

    transient { target_project { association(:project) } }

    project_id  { target_project.id }
    entity_path { target_project.full_path }
    target_details { target_project.name }
    ip_address { IPAddr.new '127.0.0.1' }
    details do
      {
        change: 'packages_enabled',
        from: true,
        to: false,
        author_name: user.name,
        target_id: target_project.id,
        target_type: 'Project',
        target_details: target_project.name,
        ip_address: '127.0.0.1',
        entity_path: target_project.full_path
      }
    end

    trait :unauthenticated do
      author_id { -1 }
      author_name { 'An unauthenticated user' }
      details do
        {
          custom_message: 'Custom action',
          author_name: 'An unauthenticated user',
          target_id: target_project.id,
          target_type: 'Project',
          target_details: target_project.name,
          ip_address: '127.0.0.1',
          entity_path: target_project.full_path
        }
      end
    end
  end
end
