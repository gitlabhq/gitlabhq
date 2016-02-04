class AddAllowGuestToAccessBuildsProject < ActiveRecord::Migration
  def change
    add_column :projects, :public_builds, :boolean, default: true, null: false
  end
end
