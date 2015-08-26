class RenameCommitterToPusher < ActiveRecord::Migration
  def change
    rename_column :projects, :email_add_committer, :email_add_pusher
  end
end
