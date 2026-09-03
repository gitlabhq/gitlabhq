# frozen_string_literal: true

# Rewrites the loose foreign keys trigger on project_repositories so deleted rows are
# routed to loose_foreign_keys_project_deleted_records. project_id is NOT NULL and is
# the table's only routable sharding key, so every deleted row produces exactly one
# routed record. Pilot table for the per-trigger rollout.
#
# CREATE OR REPLACE TRIGGER is a single statement taking SHARE ROW EXCLUSIVE, so the
# table is never left without a trigger, in either direction.
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/597949
class TrackProjectRepositoriesDeletionsWithShardingKeys < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '19.4'

  def up
    track_record_deletions_with_sharding_keys(:project_repositories)
  end

  def down
    execute(<<~SQL.squish)
      CREATE OR REPLACE TRIGGER project_repositories_loose_fk_trigger
      AFTER DELETE ON project_repositories REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT
      EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
    SQL
  end
end
