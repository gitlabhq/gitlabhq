# rubocop:disable all
class AddTemplateToLabel < ActiveRecord::Migration[4.2]
  def change
    add_column :labels, :template, :boolean, default: false
  end
end