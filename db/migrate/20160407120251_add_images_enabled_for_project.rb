class AddImagesEnabledForProject < ActiveRecord::Migration
  def change
    add_column :projects, :container_registry_enabled, :boolean
  end
end
