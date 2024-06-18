# frozen_string_literal: true

module AuditEvents
  class ProjectAuditEvent < ApplicationRecord
    self.table_name = "project_audit_events"
    include PartitionedTable

    self.primary_key = :id
    partitioned_by :created_at, strategy: :monthly
  end
end
