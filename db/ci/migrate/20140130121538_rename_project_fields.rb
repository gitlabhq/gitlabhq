class RenameProjectFields < ActiveRecord::Migration
  def change
    rename_column :projects, :email_all_broken_builds, :email_only_broken_builds
  end
end
