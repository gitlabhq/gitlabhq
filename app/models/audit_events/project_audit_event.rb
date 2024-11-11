# frozen_string_literal: true

module AuditEvents
  class ProjectAuditEvent < ApplicationRecord
    self.table_name = "project_audit_events"

    include AuditEvents::CommonModel

    validates :project_id, presence: true

    scope :by_project, ->(project_id) { where(project_id: project_id) }
  end
end

AuditEvents::ProjectAuditEvent.prepend_mod_with('AuditEvents::ProjectAuditEvent')
