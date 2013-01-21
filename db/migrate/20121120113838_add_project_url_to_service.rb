class AddProjectUrlToService < ActiveRecord::Migration
  def change
    add_column :services, :project_url, :string, null: true
  end
end
