class AddFaviconToAppearances < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :appearances, :favicon, :string
  end
end
