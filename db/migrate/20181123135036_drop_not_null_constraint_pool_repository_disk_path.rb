# frozen_string_literal: true

class DropNotNullConstraintPoolRepositoryDiskPath < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    change_column_null :pool_repositories, :disk_path, true
  end
end
