# frozen_string_literal: true

class AddIndexToComposerMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:packages_composer_metadata, [:package_id, :target_sha], unique: true)
  end

  def down
    remove_concurrent_index(:packages_composer_metadata, [:package_id, :target_sha])
  end
end
