class AddFaviconToAppearances < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :appearances, :favicon, :string
  end
end
