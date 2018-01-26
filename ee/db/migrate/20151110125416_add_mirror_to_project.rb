# rubocop:disable all
class AddMirrorToProject < ActiveRecord::Migration
  def change
    add_column :projects, :mirror, :boolean, default: false, null: false
    add_column :projects, :mirror_last_update_at, :datetime
    add_column :projects, :mirror_last_successful_update_at, :datetime
    add_column :projects, :mirror_user_id, :integer
  end
end
