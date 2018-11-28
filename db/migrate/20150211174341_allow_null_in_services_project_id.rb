class AllowNullInServicesProjectId < ActiveRecord::Migration[4.2]
  def change
    change_column :services, :project_id, :integer, null: true
  end
end
