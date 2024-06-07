# frozen_string_literal: true

module AuditEvents
  class InstanceAuditEvent < ApplicationRecord
    self.table_name = "instance_audit_events"
    include PartitionedTable

    self.primary_key = :id
    partitioned_by :created_at, strategy: :monthly
  end
end
