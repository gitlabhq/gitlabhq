class AddMoreFieldsToProject < ActiveRecord::Migration
  def change
    add_column :projects, :ssh_url_to_repo, :string
  end
end
