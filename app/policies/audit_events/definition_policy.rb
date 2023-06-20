# frozen_string_literal: true

module AuditEvents
  class DefinitionPolicy < ::BasePolicy
    condition(:read_audit_events_definitions_enabled) do
      true
    end

    rule { read_audit_events_definitions_enabled }.enable :audit_event_definitions
  end
end
