# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_user_audit_event, class: 'AuditEvents::UserAuditEvent' do
    user

    user_id { user.id }
    entity_path { user.full_path }
    target_details { user.name }
    ip_address { IPAddr.new '127.0.0.1' }
    author_name { 'Jane Doe' }
    details do
      {
        change: 'email address',
        from: 'admin@gitlab.com',
        to: 'maintainer@gitlab.com',
        author_name: 'Jane Doe',
        target_id: user.id,
        target_type: 'User',
        target_details: user.name,
        ip_address: '127.0.0.1',
        entity_path: user.full_path
      }
    end
  end
end
