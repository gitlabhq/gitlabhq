# rubocop:disable all
class AddServicesTemplateIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :services, :template
  end
end
