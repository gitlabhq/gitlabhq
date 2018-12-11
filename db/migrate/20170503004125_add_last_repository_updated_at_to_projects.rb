# rubocop:disable Migration/Datetime
class AddLastRepositoryUpdatedAtToProjects < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :projects, :last_repository_updated_at, :datetime
  end
end
