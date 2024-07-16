# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_group_audit_event, class: 'AuditEvents::GroupAuditEvent' do
    user

    transient { target_group { association(:group) } }

    group_id { target_group.id }
    entity_path { target_group.full_path }
    target_details { target_group.name }
    ip_address { IPAddr.new '127.0.0.1' }
    details do
      {
        change: 'project_creation_level',
        from: nil,
        to: 'Developers + Maintainers',
        author_name: 'Jane Doe',
        target_id: target_group.id,
        target_type: 'Group',
        target_details: target_group.name,
        ip_address: '127.0.0.1',
        entity_path: target_group.full_path
      }
    end
  end
end
