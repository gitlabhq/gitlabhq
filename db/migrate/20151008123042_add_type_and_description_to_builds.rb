# rubocop:disable all
class AddTypeAndDescriptionToBuilds < ActiveRecord::Migration[4.2]
  def change
    add_column :ci_builds, :type, :string
    add_column :ci_builds, :target_url, :string
    add_column :ci_builds, :description, :string
    add_index :ci_builds, [:commit_id, :type, :ref]
    add_index :ci_builds, [:commit_id, :type, :name, :ref]
  end
end
