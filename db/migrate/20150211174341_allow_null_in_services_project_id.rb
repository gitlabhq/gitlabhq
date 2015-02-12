class AllowNullInServicesProjectId < ActiveRecord::Migration
  def change
    change_column :services, :project_id, :integer, null: true
  end
end
