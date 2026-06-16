# frozen_string_literal: true

class AddEntriesDigestToCdVersionSets < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_column :cd_version_sets, :entries_digest, :text, null: true, if_not_exists: true
    add_text_limit :cd_version_sets, :entries_digest, 64
  end

  def down
    remove_column :cd_version_sets, :entries_digest, if_exists: true
  end
end
