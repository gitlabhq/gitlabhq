# frozen_string_literal: true

module AuditEvents
  class InstanceAuditEvent < ApplicationRecord
    self.table_name = "instance_audit_events"

    include AuditEvents::CommonModel

    def entity_id
      nil
    end

    # Gitlab::Audit::InstanceScope is EE-only, so the name is hardcoded here to
    # match the key used in Gitlab::Audit::Logging::ENTITY_TYPE_TO_CLASS.
    def entity_type
      'Gitlab::Audit::InstanceScope'
    end
  end
end

AuditEvents::InstanceAuditEvent.prepend_mod
