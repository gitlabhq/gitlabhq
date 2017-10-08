# rubocop:disable all
class AddDevelopersCanPushToProtectedBranches < ActiveRecord::Migration[4.2]
  def change
    add_column :protected_branches, :developers_can_push, :boolean, default: false, null: false
  end
end
