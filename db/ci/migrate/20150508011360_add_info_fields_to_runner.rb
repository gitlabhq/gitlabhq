class AddInfoFieldsToRunner < ActiveRecord::Migration
  def change
    add_column :runners, :name, :string
    add_column :runners, :version, :string
    add_column :runners, :revision, :string
    add_column :runners, :platform, :string
    add_column :runners, :architecture, :string
  end
end
