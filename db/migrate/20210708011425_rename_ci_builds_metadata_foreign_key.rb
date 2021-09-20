# frozen_string_literal: true

class RenameCiBuildsMetadataForeignKey < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE_NAME = 'ci_builds_metadata'
  OLD_PREFIX = 'fk_rails_'

  def up
    with_lock_retries(raise_on_exhaustion: true) do
      rename_constraint(
        TABLE_NAME,
        concurrent_foreign_key_name(TABLE_NAME, :build_id, prefix: 'fk_rails_'),
        concurrent_foreign_key_name(TABLE_NAME, :build_id)
      )
    end
  end

  def down
    with_lock_retries(raise_on_exhaustion: true) do
      rename_constraint(
        TABLE_NAME,
        concurrent_foreign_key_name(TABLE_NAME, :build_id),
        concurrent_foreign_key_name(TABLE_NAME, :build_id, prefix: 'fk_rails_')
      )
    end
  end
end
