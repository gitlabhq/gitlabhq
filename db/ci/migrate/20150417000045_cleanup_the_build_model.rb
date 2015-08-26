class CleanupTheBuildModel < ActiveRecord::Migration
  def change
    remove_column :builds, :push_data, :text
    remove_column :builds, :before_sha, :string
    remove_column :builds, :ref, :string
    remove_column :builds, :sha, :string
    remove_column :builds, :tmp_file, :string
  end
end
