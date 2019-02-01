class AddImagesEnabledForProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :container_registry_enabled, :boolean
  end
end
