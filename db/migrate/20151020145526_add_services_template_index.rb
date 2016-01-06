class AddServicesTemplateIndex < ActiveRecord::Migration
  def change
    add_index :services, :template
  end
end
