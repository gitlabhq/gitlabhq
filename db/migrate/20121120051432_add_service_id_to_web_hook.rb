class AddServiceIdToWebHook < ActiveRecord::Migration
  def change
    add_column :web_hooks, :service_id, :integer, null: true
  end
end
