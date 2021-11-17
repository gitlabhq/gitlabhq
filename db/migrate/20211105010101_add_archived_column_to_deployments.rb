# frozen_string_literal: true

class AddArchivedColumnToDeployments < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :deployments, :archived, :boolean, default: false, null: false
  end
end
