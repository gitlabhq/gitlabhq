# rubocop:disable all
class AddProjectsPublicIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :namespaces, :public
  end
end
