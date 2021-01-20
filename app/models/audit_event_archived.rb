# frozen_string_literal: true

# This model is not intended to be used.
# It is a temporary reference to the pre-partitioned
# audit_events table.
# Please refer to https://gitlab.com/groups/gitlab-org/-/epics/3206
# for details.
class AuditEventArchived < ApplicationRecord
  self.table_name = 'audit_events_archived'
end
