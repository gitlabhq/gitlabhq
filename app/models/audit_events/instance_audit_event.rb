# frozen_string_literal: true

module AuditEvents
  class InstanceAuditEvent < ApplicationRecord
    self.table_name = "instance_audit_events"

    include AuditEvents::CommonModel
  end
end

AuditEvents::InstanceAuditEvent.prepend_mod
