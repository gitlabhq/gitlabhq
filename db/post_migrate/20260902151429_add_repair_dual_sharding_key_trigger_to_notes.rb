# frozen_string_literal: true

# No-op: exhausted lock retries against an autovacuum on gprd and was marked
# as executed; replaced by 20260908184215_retry_add_repair_dual_sharding_key_trigger_to_notes.
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/627843
class AddRepairDualShardingKeyTriggerToNotes < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up; end

  def down; end
end
