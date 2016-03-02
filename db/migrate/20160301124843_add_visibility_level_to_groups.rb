class AddVisibilityLevelToGroups < ActiveRecord::Migration
  def change
    #All groups will be private when created
    add_column :namespaces, :visibility_level, :integer, null: false, default: 20
  end
end
