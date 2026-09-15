# frozen_string_literal: true

# Rewrites the loose foreign keys trigger on clusters so deleted rows are routed to the
# deleted-records table of their sharding key. clusters declares three routable keys
# (project_id, group_id, organization_id) with a CHECK enforcing exactly one non-null,
# so every deleted row produces exactly one routed record. Pilot for multi-target
# routing and for a source column (group_id) that differs from the target column
# (namespace_id).
#
# CREATE OR REPLACE TRIGGER is a single statement taking SHARE ROW EXCLUSIVE, so the
# table is never left without a trigger, in either direction.
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/597949
class TrackClustersDeletionsWithShardingKeys < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '19.4'

  def up
    track_record_deletions_with_sharding_keys(:clusters)
  end

  def down
    execute(<<~SQL.squish)
      CREATE OR REPLACE TRIGGER clusters_loose_fk_trigger
      AFTER DELETE ON clusters REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT
      EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
    SQL
  end
end
