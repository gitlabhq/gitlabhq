# rubocop:disable all
class AddTemplateToService < ActiveRecord::Migration
  def change
    add_column :services, :template, :boolean, default: false
  end
end
