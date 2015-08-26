class AddYamlToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :generated_yaml_config, :text
  end

  def down
    remove_column :projects, :generated_yaml_config
  end
end
