class AddActiveToRunner < ActiveRecord::Migration
  def change
    add_column :runners, :active, :boolean, null: false, default: true
  end
end
