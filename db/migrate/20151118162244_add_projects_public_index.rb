class AddProjectsPublicIndex < ActiveRecord::Migration
  def change
    add_index :namespaces, :public
  end
end
