class AddAllowGuestToAccessBuildsProject < ActiveRecord::Migration
  def change
    add_column :projects, :allow_guest_to_access_builds, :boolean, default: true, null: false
  end
end
