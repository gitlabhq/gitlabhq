# rubocop:disable all
class AddTemplateToService < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :template, :boolean, default: false
  end
end
