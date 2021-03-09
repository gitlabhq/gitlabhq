# frozen_string_literal: true

# This model is not yet intended to be used.
# It is in a transitioning phase while we are partitioning
# the web_hook_logs table on the database-side.
# Please refer to https://gitlab.com/groups/gitlab-org/-/epics/5558
# for details.
# rubocop:disable Gitlab/NamespacedClass: This is a temporary class with no relevant namespace
#  WebHook, WebHookLog and all hooks are defined outside of a namespace
class WebHookLogPartitioned < ApplicationRecord
  include PartitionedTable

  self.table_name = 'web_hook_logs_part_0c5294f417'
  self.primary_key = :id

  partitioned_by :created_at, strategy: :monthly
end
