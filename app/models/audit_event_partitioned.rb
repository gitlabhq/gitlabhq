# frozen_string_literal: true

# This model is not yet intended to be used.
# It is in a transitioning phase while we are partitioning
# the table on the database-side.
# Please refer to https://gitlab.com/groups/gitlab-org/-/epics/3206
# for details.
class AuditEventPartitioned < ApplicationRecord
  include PartitionedTable

  self.table_name = 'audit_events_part_5fc467ac26'

  partitioned_by :created_at, strategy: :monthly
end
