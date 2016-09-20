# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MergeRequestDiffRemoveUniq < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    constraint_name = 'merge_request_diffs_merge_request_id_key'

    transaction do
      if index_exists?(:merge_request_diffs, :merge_request_id)
        remove_index(:merge_request_diffs, :merge_request_id)
      end

      # In some bizarre cases PostgreSQL might have a separate unique constraint
      # that we'll need to drop.
      if constraint_exists?(constraint_name) && Gitlab::Database.postgresql?
        execute("ALTER TABLE merge_request_diffs DROP CONSTRAINT IF EXISTS #{constraint_name};")
      end
    end
  end

  def down
    unless index_exists?(:merge_request_diffs, :merge_request_id)
      add_concurrent_index(:merge_request_diffs, :merge_request_id, unique: true)
    end
  end

  def constraint_exists?(name)
    indexes(:merge_request_diffs).map(&:name).include?(name)
  end
end
