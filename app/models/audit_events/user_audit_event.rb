# frozen_string_literal: true

module AuditEvents
  class UserAuditEvent < ApplicationRecord
    self.table_name = "user_audit_events"

    include AuditEvents::CommonModel

    validates :user_id, presence: true

    scope :by_user, ->(user_id) { where(user_id: user_id) }
    scope :by_username, ->(username) { where(user_id: find_user_id(username)) }

    def entity_id
      user_id
    end

    def entity_type
      'User'
    end
  end
end

AuditEvents::UserAuditEvent.prepend_mod
