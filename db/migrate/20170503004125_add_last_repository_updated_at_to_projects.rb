# rubocop:disable Migration/Datetime
class AddLastRepositoryUpdatedAtToProjects < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :projects, :last_repository_updated_at, :datetime
  end
end
