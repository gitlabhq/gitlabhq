# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_user_audit_event, class: 'AuditEvents::UserAuditEvent' do
    # `user` is the audited user on this model, so the author is kept in a
    # transient to avoid writing the `belongs_to :user` association (which is
    # keyed on author_id) and shadowing the EE `user` reader.
    transient do
      author { association(:user) }
      target_user { association(:user) }
    end

    user_id { target_user.id }
    author_id { author.id }
    author_name { author.name }
    entity_path { target_user.full_path }
    target_details { target_user.name }
    ip_address { IPAddr.new '127.0.0.1' }
    details do
      {
        change: 'email address',
        from: 'admin@gitlab.com',
        to: 'maintainer@gitlab.com',
        author_name: author.name,
        target_id: target_user.id,
        target_type: 'User',
        target_details: target_user.name,
        ip_address: '127.0.0.1',
        entity_path: target_user.full_path
      }
    end

    trait :composite_identity_author do
      author_name { 'Service Account on behalf of @human' }
      details { { author_class: ::Gitlab::Audit::CompositeIdentityAuthor.name } }
    end
  end
end
