class AddErrorsToCommit < ActiveRecord::Migration
  def change
    add_column :commits, :yaml_errors, :text
  end
end