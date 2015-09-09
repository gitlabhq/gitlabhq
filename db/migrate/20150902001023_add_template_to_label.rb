class AddTemplateToLabel < ActiveRecord::Migration
  def change
    add_column :labels, :template, :boolean, default: false
  end
end