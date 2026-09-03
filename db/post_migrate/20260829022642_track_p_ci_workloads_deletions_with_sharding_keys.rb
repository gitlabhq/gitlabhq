# frozen_string_literal: true

# Rewrites the loose foreign keys trigger on the partitioned p_ci_workloads table so
# deleted rows are routed to loose_foreign_keys_project_deleted_records. project_id is
# NOT NULL and is the table's only routable sharding key, so every deleted row produces
# exactly one routed record. Pilot for partitioned tables and for the ci database.
#
# Only the parent trigger is rewritten. A statement trigger on the parent receives the
# rows deleted from every partition, and Ci::Workloads::Workload deletes through the
# parent, so partition-direct deletes keep their own plain trigger and stay cell-local
# until the rollout of phase 4.
#
# CREATE OR REPLACE TRIGGER is a single statement taking SHARE ROW EXCLUSIVE, so the
# table is never left without a trigger, in either direction.
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/597949
class TrackPCiWorkloadsDeletionsWithShardingKeys < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '19.4'

  def up
    track_record_deletions_override_table_name_with_sharding_keys(:p_ci_workloads)
  end

  def down
    execute(<<~SQL.squish)
      CREATE OR REPLACE TRIGGER p_ci_workloads_loose_fk_trigger
      AFTER DELETE ON p_ci_workloads REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT
      EXECUTE FUNCTION #{INSERT_FUNCTION_NAME_OVERRIDE_TABLE}('p_ci_workloads');
    SQL
  end
end
