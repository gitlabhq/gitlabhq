class AddVisibilityLevelToGroups < ActiveRecord::Migration
  def change
    #All groups will be private when created
    add_column :namespaces, :visibility_level, :integer, null: false, default: 0

    #Set all existing groups to public
    Group.update_all(visibility_level: 20)
  end
end
