# frozen_string_literal: true

class AddVersionShaCacheToComposerMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :packages_composer_metadata, :version_cache_sha, :binary, null: true
    end
  end

  def down
    with_lock_retries do
      remove_column :packages_composer_metadata, :version_cache_sha, :binary
    end
  end
end
