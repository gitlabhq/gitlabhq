class AddImagesEnabledForProject < ActiveRecord::Migration
  def change
    add_column :projects, :images_enabled, :boolean
  end
end
