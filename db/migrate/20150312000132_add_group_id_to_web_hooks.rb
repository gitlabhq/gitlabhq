class AddGroupIdToWebHooks < ActiveRecord::Migration
  def change
    add_column :web_hooks, :group_id, :integer, after: :project_id
  end
end
