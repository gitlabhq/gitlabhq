# frozen_string_literal: true

class RemoveMinergateTriggerOnGitLabCom < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless Gitlab.com?

    with_lock_retries do
      execute <<~SQL
        DROP TRIGGER IF EXISTS ci_builds_block_minergate ON ci_builds;
      SQL
    end

    execute <<~SQL
      DROP FUNCTION IF EXISTS make_build_to_be_stuck_with_lock_version();
      DROP FUNCTION IF EXISTS make_build_to_be_stuck();
    SQL
  end

  def down
    # no-op
  end
end
