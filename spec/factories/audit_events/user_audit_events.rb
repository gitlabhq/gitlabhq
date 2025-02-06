# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_user_audit_event, class: 'AuditEvents::UserAuditEvent' do
    user

    transient { target_user { association(:user) } }

    user_id { target_user.id }
    author_id { user.id }
    author_name { user.name }
    entity_path { target_user.full_path }
    target_details { target_user.name }
    ip_address { IPAddr.new '127.0.0.1' }
    details do
      {
        change: 'email address',
        from: 'admin@gitlab.com',
        to: 'maintainer@gitlab.com',
        author_name: user.name,
        target_id: target_user.id,
        target_type: 'User',
        target_details: target_user.name,
        ip_address: '127.0.0.1',
        entity_path: target_user.full_path
      }
    end
  end
end
