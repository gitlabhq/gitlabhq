# frozen_string_literal: true

module AuditEvents
  class GroupAuditEvent < ApplicationRecord
    self.table_name = "group_audit_events"

    include AuditEvents::CommonModel

    validates :group_id, presence: true

    scope :by_group, ->(group_id) { where(group_id: group_id) }
  end
end

AuditEvents::GroupAuditEvent.prepend_mod_with('AuditEvents::GroupAuditEvent')
