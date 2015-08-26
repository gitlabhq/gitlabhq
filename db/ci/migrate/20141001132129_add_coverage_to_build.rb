class AddCoverageToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :coverage, :float
  end
end
