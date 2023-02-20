# frozen_string_literal: true

class AddChecksumsColumnToProjectMirrorData < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :project_mirror_data, :checksums, :jsonb, null: false, default: {}
  end
end
