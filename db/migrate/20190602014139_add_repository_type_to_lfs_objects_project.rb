# frozen_string_literal: true

class AddRepositoryTypeToLfsObjectsProject < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :lfs_objects_projects, :repository_type, :integer, limit: 2, null: true
  end
end
