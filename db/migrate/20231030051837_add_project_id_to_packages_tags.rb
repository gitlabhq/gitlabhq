# frozen_string_literal: true

class AddProjectIdToPackagesTags < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  enable_lock_retries!

  def change
    add_column :packages_tags, :project_id, :bigint
  end
end
