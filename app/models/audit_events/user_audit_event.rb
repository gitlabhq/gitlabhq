# frozen_string_literal: true

module AuditEvents
  class UserAuditEvent < ApplicationRecord
    self.table_name = "user_audit_events"
    include PartitionedTable

    self.primary_key = :id
    partitioned_by :created_at, strategy: :monthly
  end
end
