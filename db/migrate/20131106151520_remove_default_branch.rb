# rubocop:disable all
class RemoveDefaultBranch < ActiveRecord::Migration[4.2]
  def up
    remove_column :projects, :default_branch
  end

  def down
    add_column :projects, :default_branch, :string
  end
end
