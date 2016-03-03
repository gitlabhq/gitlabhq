class AddVisibilityLevelToGroups < ActiveRecord::Migration
  def change
    #All groups public by default
    add_column :namespaces, :visibility_level, :integer, null: false, default: 20
  end
end
