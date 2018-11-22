# rubocop:disable all
class AddAllowGuestToAccessBuildsProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :public_builds, :boolean, default: true, null: false
  end
end
