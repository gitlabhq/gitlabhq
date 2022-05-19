# frozen_string_literal: true

class AddSeparatedCachesOptionToProjectCiSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :project_ci_cd_settings, :separated_caches, :boolean, default: true, null: false
  end
end
